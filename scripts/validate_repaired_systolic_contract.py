"""Validate the repaired systolic GEMM checker with a deterministic oracle DUT."""

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
    / "systolic_gemm"
)
OUT_ROOT = REPO_ROOT / "artifacts" / "contract_validation" / "systolic_20260716"

A_SQUARED = [
    90, 100, 110, 120,
    202, 228, 254, 280,
    314, 356, 398, 440,
    426, 484, 542, 600,
]
A_IDENTITY = list(range(16))


def oracle_verilog() -> str:
    result_ports = ",\n    ".join(
        f"output wire [63:0] result{i}" for i in range(16)
    )
    result_assignments = "\n".join(
        f"  assign result{i} = second_case ? 64'd{A_IDENTITY[i]} : 64'd{A_SQUARED[i]};"
        for i in range(16)
    )
    return f"""`timescale 1ns/1ps

module systolic_matrix_mult (
    input wire [31:0] a_west0, a_west1, a_west2, a_west3,
    input wire [31:0] b_north0, b_north1, b_north2, b_north3,
    input wire clk,
    input wire rst,
    output wire done,
    {result_ports}
);
  reg seen_reset = 1'b0;
  reg second_case = 1'b0;

  always @(posedge clk) begin
    if (rst) begin
      if (seen_reset)
        second_case <= 1'b1;
      else
        seen_reset <= 1'b1;
    end
  end

  assign done = 1'b1;
{result_assignments}
endmodule
"""


def main() -> int:
    if OUT_ROOT.exists():
        shutil.rmtree(OUT_ROOT)
    OUT_ROOT.mkdir(parents=True)

    shutil.copy2(FIXTURE / "tb.v", OUT_ROOT / "tb.v")
    shutil.copy2(FIXTURE / "REPAIRED_CONTRACT.md", OUT_ROOT / "REPAIRED_CONTRACT.md")
    (OUT_ROOT / "oracle_dut.v").write_text(oracle_verilog(), encoding="ascii")

    _, _, selected_testbench = read_benchmark(str(FIXTURE))
    selected_checker_matches = selected_testbench == (FIXTURE / "tb.v").read_text(encoding="utf-8")

    iverilog = find_tool(["iverilog"])
    vvp = find_tool(["vvp"])
    if not iverilog or not vvp:
        raise SystemExit("Icarus Verilog toolchain is unavailable")

    executable = OUT_ROOT / "sim.vvp"
    compile_proc = subprocess.run(
        [iverilog, "-g2012", "-o", str(executable), "tb.v", "oracle_dut.v"],
        cwd=OUT_ROOT,
        capture_output=True,
        text=True,
        encoding="utf-8",
        errors="replace",
        timeout=60,
    )
    if compile_proc.returncode != 0:
        raise SystemExit(compile_proc.stdout + compile_proc.stderr)

    sim_proc = subprocess.run(
        [vvp, str(executable)],
        cwd=OUT_ROOT,
        capture_output=True,
        text=True,
        encoding="utf-8",
        errors="replace",
        timeout=60,
    )
    output = sim_proc.stdout + sim_proc.stderr
    (OUT_ROOT / "sim_output.log").write_text(output, encoding="utf-8")

    output_passes = len(re.findall(r"^\[PASS\]", output, re.MULTILINE))
    output_failures = len(re.findall(r"^\[FAIL\]", output, re.MULTILINE))
    summary_ok = "TEST SUMMARY: 32 PASS, 0 FAILED" in output
    status = (
        "pass"
        if sim_proc.returncode == 0
        and selected_checker_matches
        and output_passes == 32
        and output_failures == 0
        and summary_ok
        else "fail"
    )
    result = {
        "status": status,
        "returncode": sim_proc.returncode,
        "selected_checker": "tb.v",
        "selected_checker_matches": selected_checker_matches,
        "output_checks_passed": output_passes,
        "output_checks_failed": output_failures,
        "expected_output_checks": 32,
        "summary_ok": summary_ok,
    }
    (OUT_ROOT / "validation_results.json").write_text(
        json.dumps(result, indent=2) + "\n",
        encoding="utf-8",
    )
    executable.unlink(missing_ok=True)
    print(json.dumps(result, indent=2))
    return 0 if status == "pass" else 1


if __name__ == "__main__":
    raise SystemExit(main())
