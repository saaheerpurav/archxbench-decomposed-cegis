"""Validate the repaired Harris dimensions, drain, count, and exact-value contract."""

from __future__ import annotations

import json
import re
import shutil
import subprocess
import sys
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(REPO_ROOT))

from cegis.tdes.fpga.autonomous.orchestrator import read_benchmark
from cegis.tdes.fpga.verilog_runner import find_tool


FIXTURE = (
    REPO_ROOT
    / "artifacts"
    / "benchmark_contracts"
    / "archxbench_repaired"
    / "level-5"
    / "harris_corner_detection"
)
OUT_ROOT = REPO_ROOT / "artifacts" / "contract_validation" / "harris_20260716"
N = 128 * 128


def oracle_verilog(mode: str) -> str:
    if mode not in {"normal", "short", "extra", "inverted"}:
        raise ValueError(mode)
    normal_limit = N - 1 if mode == "short" else N
    extra_expr = " || (!valid_in && index == N)" if mode == "extra" else ""
    value_expr = "~golden[index]" if mode == "inverted" else "golden[index]"
    return f"""`timescale 1ns/1ps

module harris_corner #(
    parameter IMG_WIDTH = 128,
    parameter IMG_HEIGHT = 128,
    parameter PIXEL_W = 8,
    parameter GRAD_W = 16,
    parameter RESP_W = 32,
    parameter K_W = 8
) (
    input wire clk,
    input wire rst,
    input wire [PIXEL_W-1:0] pixel_in,
    input wire valid_in,
    input wire [RESP_W-1:0] threshold,
    input wire [K_W-1:0] k_param,
    output wire is_corner,
    output wire valid_out
);
    localparam N = IMG_WIDTH * IMG_HEIGHT;
    reg golden [0:N-1];
    integer index;

    initial begin
        $readmemb("outputs/golden_bits.mem", golden);
        index = 0;
    end

    assign valid_out = (valid_in && index < {normal_limit}){extra_expr};
    assign is_corner = (index < N) ? {value_expr} : 1'b0;

    always @(posedge clk) begin
        if (rst)
            index <= 0;
        else if (valid_in && index < N)
            index <= index + 1;
        else if ({"1'b1" if mode == "extra" else "1'b0"} && !valid_in && index == N)
            index <= index + 1;
    end
endmodule
"""


def load_bits(path: Path) -> list[int]:
    data = json.loads(path.read_text(encoding="utf-8"))
    if len(data) != N or any(item not in (0, 1) for item in data):
        raise ValueError(f"expected {N} binary values in {path}")
    return data


def run_mode(mode: str, iverilog: str, vvp: str, golden: list[int]) -> dict:
    work = OUT_ROOT / mode
    if work.exists():
        shutil.rmtree(work)
    shutil.copytree(FIXTURE, work)
    (work / "outputs" / "dut_output.json").unlink(missing_ok=True)
    (work / "outputs" / "golden_bits.mem").write_text(
        "\n".join(str(bit) for bit in golden) + "\n",
        encoding="ascii",
    )
    (work / "oracle_dut.v").write_text(oracle_verilog(mode), encoding="ascii")

    executable = work / "sim.vvp"
    compile_proc = subprocess.run(
        [iverilog, "-g2012", "-o", str(executable), "tb_harris_corner.v", "oracle_dut.v"],
        cwd=work,
        capture_output=True,
        text=True,
        encoding="utf-8",
        errors="replace",
        timeout=60,
    )
    if compile_proc.returncode != 0:
        return {"mode": mode, "status": "compile_failed", "detail": compile_proc.stdout + compile_proc.stderr}

    sim_proc = subprocess.run(
        [vvp, str(executable)],
        cwd=work,
        capture_output=True,
        text=True,
        encoding="utf-8",
        errors="replace",
        timeout=120,
    )
    output = sim_proc.stdout + sim_proc.stderr
    (work / "sim_output.log").write_text(output, encoding="utf-8")
    dut_path = work / "outputs" / "dut_output.json"
    dut = json.loads(dut_path.read_text(encoding="utf-8")) if dut_path.is_file() else []
    exact_matches = sum(actual == expected for actual, expected in zip(dut, golden))
    exact_full_match = len(dut) == len(golden) and exact_matches == len(golden)
    return {
        "mode": mode,
        "returncode": sim_proc.returncode,
        "dut_count": len(dut),
        "golden_count": len(golden),
        "exact_matches": exact_matches,
        "exact_full_match": exact_full_match,
        "native_pass": bool(re.search(r"^\[PASS\]", output, re.MULTILINE)),
        "native_fail": bool(re.search(r"^\[FAIL\]", output, re.MULTILINE)),
    }


def main() -> int:
    OUT_ROOT.mkdir(parents=True, exist_ok=True)
    golden = load_bits(FIXTURE / "outputs" / "golden_output.json")
    stimuli = json.loads((FIXTURE / "inputs" / "stimuli.json").read_text(encoding="utf-8"))
    _, _, selected_testbench = read_benchmark(str(FIXTURE))
    selected_checker_matches = selected_testbench == (FIXTURE / "tb_harris_corner.v").read_text(encoding="utf-8")

    iverilog = find_tool(["iverilog"])
    vvp = find_tool(["vvp"])
    if not iverilog or not vvp:
        raise SystemExit("Icarus Verilog toolchain is unavailable")

    rows = {mode: run_mode(mode, iverilog, vvp, golden) for mode in ("normal", "short", "extra", "inverted")}
    normal = rows["normal"]
    short = rows["short"]
    extra = rows["extra"]
    inverted = rows["inverted"]
    status = "pass" if (
        len(stimuli) == N
        and selected_checker_matches
        and normal.get("native_pass") and normal.get("exact_full_match")
        and short.get("native_fail") and short.get("dut_count") == N - 1
        and extra.get("native_fail") and extra.get("dut_count") == N + 1
        and inverted.get("native_pass") and not inverted.get("exact_full_match")
        and inverted.get("exact_matches") == 0
    ) else "fail"
    result = {
        "status": status,
        "dimensions": [128, 128],
        "stimulus_count": len(stimuli),
        "golden_count": len(golden),
        "golden_ones": sum(golden),
        "selected_checker_matches": selected_checker_matches,
        "comparison": "exact binary equality and exact length",
        "modes": rows,
    }
    (OUT_ROOT / "validation_results.json").write_text(
        json.dumps(result, indent=2) + "\n",
        encoding="utf-8",
    )
    print(json.dumps(result, indent=2))
    return 0 if status == "pass" else 1


if __name__ == "__main__":
    raise SystemExit(main())
