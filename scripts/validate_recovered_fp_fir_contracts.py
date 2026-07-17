"""Acceptance checks for the recovered L6 floating-point FIR contracts.

Checks performed for every recovered fixture:

1. Compile and run the repaired testbench against a deterministic golden
   oracle DUT using OSS CAD Suite Icarus Verilog.
2. Score the produced output through the production contract-aware comparator.
3. Prove that all-zero, truncated, overlong, and NaN outputs are rejected.
4. Recompute the causal FIR with rounded binary32 multiply/add operations and
   verify the released golden within the explicit 1e-6 tolerance, including
   the 899-sample holdout after the 101-sample transient.
"""

from __future__ import annotations

import importlib.util
import json
import math
import os
import shutil
import struct
import subprocess
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[1]
ROOT = (
    REPO_ROOT
    / "artifacts"
    / "benchmark_contracts"
    / "archxbench_recovered_fp_low"
    / "level-6"
)
OUT = REPO_ROOT / "artifacts" / "contract_validation" / "fp_fir_recovered"

DESIGNS = {
    "fp_low_pass_fir": {
        "module": "fp_lowpass_fir",
        "tb": "tb_fp_lowpass_fir.v",
    },
    "fp_band_pass_fir": {
        "module": "fp_bandpass_fir",
        "tb": "tb_fp_band_pass_fir.v",
    },
    "fp_high_pass_fir": {
        "module": "fp_highpass_fir",
        "tb": "tb_fp_high_pass_fir.v",
    },
}


def _load_comparator():
    path = REPO_ROOT / "cegis" / "tdes" / "fpga" / "autonomous" / "golden_compare.py"
    spec = importlib.util.spec_from_file_location("strict_golden_compare", path)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"Could not import comparator from {path}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


COMPARE = _load_comparator()


def _fp32_word(item) -> int:
    if isinstance(item, str):
        return int(item, 16)
    if isinstance(item, int) and not isinstance(item, bool):
        return item
    raise ValueError(f"not an FP32 word: {item!r}")


def _fp32_value(item) -> float:
    return struct.unpack("!f", struct.pack("!I", _fp32_word(item)))[0]


def _round_fp32(value: float) -> float:
    return struct.unpack("!f", struct.pack("!f", value))[0]


def _find_oss_tools() -> tuple[Path, Path, dict[str, str]]:
    direct_iverilog = shutil.which("iverilog")
    direct_vvp = shutil.which("vvp")
    if direct_iverilog and direct_vvp:
        return Path(direct_iverilog), Path(direct_vvp), os.environ.copy()

    suite_bin = REPO_ROOT.parent / "tools" / "oss-cad-suite" / "bin"
    iverilog = suite_bin / "iverilog.exe"
    vvp = suite_bin / "vvp.exe"
    if not iverilog.exists() or not vvp.exists():
        raise FileNotFoundError(
            "OSS CAD Suite Icarus tools not found on PATH or under "
            f"{suite_bin}"
        )
    env = os.environ.copy()
    suite_lib = suite_bin.parent / "lib"
    env["OSS_CAD_SUITE_ROOT"] = str(suite_bin.parent)
    env["PATH"] = (
        str(suite_bin)
        + os.pathsep
        + str(suite_lib)
        + os.pathsep
        + env.get("PATH", "")
    )
    return iverilog, vvp, env


def _oracle_verilog(module_name: str, sample_count: int) -> str:
    return f"""`timescale 1ns/1ps

module {module_name} #(parameter TAP_CNT = 101) (
    input wire clk,
    input wire rst,
    input wire valid_in,
    input wire [31:0] data_in,
    output reg valid_out,
    output reg [31:0] data_out
);
    reg [31:0] golden [0:{sample_count - 1}];
    integer index;

    initial begin
        $readmemh("outputs/golden_words.mem", golden);
        index = 0;
        valid_out = 0;
        data_out = 0;
    end

    always @(posedge clk) begin
        if (rst) begin
            index <= 0;
            valid_out <= 0;
            data_out <= 0;
        end else begin
            valid_out <= valid_in && index < {sample_count};
            if (valid_in && index < {sample_count}) begin
                data_out <= golden[index];
                index <= index + 1;
            end
        end
    end
endmodule
"""


def _semantic_check(fixture: Path) -> dict:
    contract = json.loads((fixture / "recovered_fir_contract.json").read_text())
    stimuli_raw = json.loads((fixture / "inputs" / "stimuli.json").read_text())
    golden_raw = json.loads((fixture / "outputs" / "golden_output.json").read_text())
    coefficients = [_fp32_value(item) for item in contract["coefficient_words_fp32"]]
    stimuli = [_fp32_value(item) for item in stimuli_raw]
    golden = [_fp32_value(item) for item in golden_raw]
    if len(coefficients) != 101 or len(stimuli) != 1000 or len(golden) != 1000:
        raise AssertionError("unexpected FIR contract cardinality")

    predicted = []
    for sample_index in range(len(stimuli)):
        accumulator = _round_fp32(0.0)
        for tap_index, coefficient in enumerate(coefficients):
            if sample_index < tap_index:
                break
            product = _round_fp32(stimuli[sample_index - tap_index] * coefficient)
            accumulator = _round_fp32(accumulator + product)
        predicted.append(accumulator)

    errors = [abs(reference - candidate) for reference, candidate in zip(golden, predicted)]
    result = {
        "max_abs_error": max(errors),
        "holdout_start": 101,
        "holdout_count": len(errors[101:]),
        "holdout_max_abs_error": max(errors[101:]),
    }
    if result["max_abs_error"] > 1e-6 or result["holdout_max_abs_error"] > 1e-6:
        raise AssertionError(f"semantic FIR check failed: {result}")
    return result


def _score_variant(fixture: Path, work: Path, values: list) -> dict:
    outputs = work / "outputs"
    outputs.mkdir(parents=True, exist_ok=True)
    (outputs / "dut_output.json").write_text(
        json.dumps(values, indent=2) + "\n",
        encoding="utf-8",
    )
    passes, total, detail = COMPARE.compare_output_files(fixture, work)
    return {
        "passes": passes,
        "total": total,
        "accepted": total > 0 and passes == total,
        "detail": detail,
    }


def _validate_one(design: str, cfg: dict, tools: tuple[Path, Path, dict[str, str]]) -> dict:
    fixture = ROOT / design
    work = OUT / design
    if work.exists():
        shutil.rmtree(work)
    shutil.copytree(fixture, work)

    golden = json.loads((fixture / "outputs" / "golden_output.json").read_text())
    words = [f"{_fp32_word(item):08x}" for item in golden]
    (work / "outputs" / "golden_words.mem").write_text(
        "\n".join(words) + "\n",
        encoding="ascii",
    )
    (work / "oracle_dut.v").write_text(
        _oracle_verilog(cfg["module"], len(golden)),
        encoding="ascii",
    )
    dut_output = work / "outputs" / "dut_output.json"
    if dut_output.exists():
        dut_output.unlink()

    iverilog, vvp, env = tools
    executable = work / "simv.vvp"
    compile_proc = subprocess.run(
        [
            str(iverilog),
            "-g2012",
            "-s",
            f"tb_{design}" if design != "fp_low_pass_fir" else "tb_lowpass_fir_fp",
            "-o",
            str(executable),
            cfg["tb"],
            "oracle_dut.v",
        ],
        cwd=work,
        env=env,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        timeout=60,
    )
    if compile_proc.returncode != 0:
        raise RuntimeError(f"{design} oracle compile failed:\n{compile_proc.stdout}")
    sim_proc = subprocess.run(
        [str(vvp), str(executable)],
        cwd=work,
        env=env,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        timeout=120,
    )
    if sim_proc.returncode != 0 or not dut_output.exists():
        raise RuntimeError(f"{design} oracle simulation failed:\n{sim_proc.stdout}")

    oracle_values = json.loads(dut_output.read_text())
    controls = {
        "positive_oracle": _score_variant(fixture, work, oracle_values),
        "all_zero": _score_variant(fixture, work, ["0x00000000"] * len(golden)),
        "short": _score_variant(fixture, work, golden[:-1]),
        "extra": _score_variant(fixture, work, golden + [golden[-1]]),
        "nan": _score_variant(
            fixture,
            work,
            ["0x7fc00000"] + golden[1:],
        ),
    }
    if not controls["positive_oracle"]["accepted"]:
        raise AssertionError(f"{design}: positive oracle was rejected")
    for name in ("all_zero", "short", "extra", "nan"):
        if controls[name]["accepted"]:
            raise AssertionError(f"{design}: negative control {name} was accepted")

    return {
        "design": design,
        "status": "pass",
        "semantic_check": _semantic_check(fixture),
        "oracle_output_count": len(oracle_values),
        "sim_stdout_tail": sim_proc.stdout[-1000:],
        "controls": controls,
    }


def main() -> int:
    import argparse

    global ROOT, OUT
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--root",
        type=Path,
        default=ROOT,
        help="level-6 directory containing the three recovered FP FIR fixtures",
    )
    parser.add_argument(
        "--out",
        type=Path,
        default=OUT,
        help="validation artifact directory",
    )
    args = parser.parse_args()
    ROOT = args.root.resolve()
    OUT = args.out.resolve()
    OUT.mkdir(parents=True, exist_ok=True)
    tools = _find_oss_tools()
    results = [_validate_one(design, cfg, tools) for design, cfg in DESIGNS.items()]
    summary = {
        "status": "pass",
        "comparator_version": COMPARE.VERIFIER_VERSION,
        "absolute_tolerance": 1e-6,
        "results": results,
    }
    (OUT / "validation_results.json").write_text(
        json.dumps(summary, indent=2) + "\n",
        encoding="utf-8",
    )
    print(json.dumps(summary, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
