"""Validate repaired FP FIR executable contracts with an oracle DUT.

This checks only the repaired testbench/file-output contract. It does not prove
the benchmark semantics are correct; it proves the fixture can compile, run, and
score a known-good output stream through the same executable contract used by
the synthesis runner.
"""

from __future__ import annotations

import json
import shutil
import subprocess
from pathlib import Path


REPO = Path(__file__).resolve().parents[1]
ROOT = REPO / "artifacts" / "benchmark_contracts" / "archxbench_repaired" / "level-6"
OUT = REPO / "artifacts" / "contract_validation" / "fp_fir_20260707"

DESIGNS = {
    "fp_band_pass_fir": {
        "module": "fp_bandpass_fir",
        "tb": "tb_fp_band_pass_fir.v",
    },
    "fp_high_pass_fir": {
        "module": "fp_highpass_fir",
        "tb": "tb_fp_high_pass_fir.v",
    },
}


def oracle_verilog(module: str, golden_count: int) -> str:
    return f"""`timescale 1ns/1ps

module {module} #(parameter TAP_CNT = 31) (
    input wire clk,
    input wire rst,
    input wire valid_in,
    input wire [31:0] data_in,
    output wire valid_out,
    output wire [31:0] data_out
);
    reg [31:0] golden [0:{golden_count - 1}];
    integer idx;

    initial begin
        $readmemh("outputs/golden_words.mem", golden);
        idx = 0;
    end

    assign valid_out = (idx < {golden_count});
    assign data_out = (idx < {golden_count}) ? golden[idx] : 32'h00000000;

    always @(negedge clk) begin
        if (rst) begin
            idx <= 0;
        end else if (valid_in && idx < {golden_count}) begin
            idx <= idx + 1;
        end
    end
endmodule
"""


def parse_hex_word(item) -> str:
    if isinstance(item, str):
        text = item.strip().lower()
        if text.startswith("0x"):
            text = text[2:]
        return text.zfill(8)[-8:]
    if isinstance(item, int):
        return f"{item & 0xFFFFFFFF:08x}"
    raise TypeError(f"unsupported golden item: {item!r}")


def load_words(path: Path) -> list[str]:
    data = json.loads(path.read_text(encoding="utf-8"))
    if isinstance(data, dict):
        data = list(data.values())
    if data and isinstance(data[0], list):
        data = [item for row in data for item in row]
    return [parse_hex_word(item) for item in data]


def run_one(design: str, cfg: dict) -> dict:
    src = ROOT / design
    work = OUT / design
    if work.exists():
        shutil.rmtree(work)
    shutil.copytree(src, work)

    golden_words = load_words(work / "outputs" / "golden_output.json")
    (work / "outputs" / "golden_words.mem").write_text(
        "\n".join(golden_words) + "\n",
        encoding="ascii",
    )
    (work / "oracle_dut.v").write_text(
        oracle_verilog(cfg["module"], len(golden_words)),
        encoding="ascii",
    )

    exe = work / "simv"
    compile_cmd = ["iverilog", "-g2012", "-o", str(exe), cfg["tb"], "oracle_dut.v"]
    compile_proc = subprocess.run(
        compile_cmd,
        cwd=work,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        timeout=60,
    )
    if compile_proc.returncode != 0:
        return {
            "design": design,
            "status": "compile_failed",
            "detail": compile_proc.stdout,
        }

    sim_proc = subprocess.run(
        ["vvp", str(exe)],
        cwd=work,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        timeout=120,
    )
    if sim_proc.returncode != 0:
        return {
            "design": design,
            "status": "sim_failed",
            "detail": sim_proc.stdout,
        }

    dut_path = work / "outputs" / "dut_output.json"
    if not dut_path.exists():
        return {
            "design": design,
            "status": "no_dut_output",
            "detail": sim_proc.stdout,
        }

    dut_words = load_words(dut_path)
    correct = sum(1 for g, d in zip(golden_words, dut_words) if g == d)
    total = len(golden_words)
    mismatches = [
        {"index": i, "golden": g, "dut": d}
        for i, (g, d) in enumerate(zip(golden_words, dut_words))
        if g != d
    ][:10]
    return {
        "design": design,
        "status": "pass" if correct == total and len(dut_words) == total else "mismatch",
        "correct": correct,
        "total": total,
        "dut_count": len(dut_words),
        "first_mismatches": mismatches,
        "sim_stdout_tail": sim_proc.stdout[-1000:],
    }


def main() -> int:
    OUT.mkdir(parents=True, exist_ok=True)
    results = [run_one(design, cfg) for design, cfg in DESIGNS.items()]
    (OUT / "validation_results.json").write_text(
        json.dumps(results, indent=2) + "\n",
        encoding="utf-8",
    )
    for row in results:
        print(json.dumps(row, indent=2))
    return 0 if all(row.get("status") == "pass" for row in results) else 1


if __name__ == "__main__":
    raise SystemExit(main())
