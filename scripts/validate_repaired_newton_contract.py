"""Validate the repaired Newton-Raphson polynomial executable contract.

The repaired checker skips only three unsatisfiable polynomial-residual checks
from the released ArchXBench testbench. This script builds an oracle DUT that
returns fixed-point roots chosen to satisfy every remaining root/residual check.
"""

from __future__ import annotations

import json
import math
import re
import shutil
import subprocess
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[1]
FIXTURE = (
    REPO_ROOT
    / "artifacts"
    / "benchmark_contracts"
    / "archxbench_repaired"
    / "level-3"
    / "newton_raphson_polynomial"
)
OUT_ROOT = REPO_ROOT / "artifacts" / "contract_validation" / "newton_20260707"
WIDTH = 16
FRAC = 8
EPSILON = 8 / (1 << FRAC)
SKIP_RESIDUAL_CASES = {6, 13, 35}


def expected_root(a0: float, a1: float, a2: float, a3: float, x0: float) -> float:
    x = x0
    for _ in range(50):
        p = a0 + a1 * x + a2 * x * x + a3 * x * x * x
        p_prime = a1 + 2.0 * a2 * x + 3.0 * a3 * x * x
        if p_prime != 0.0:
            x = x - (p / p_prime)
    return x


def case_params(i: int) -> tuple[float, float, float, float, float]:
    general = [
        (1.0, -3.0, 2.0, 0.0, 1.5),
        (0.0, 1.0, -6.0, 2.0, 3.0),
        (2.0, -4.0, 1.0, 0.5, 0.5),
        (-1.0, 2.0, -1.0, 0.2, -0.5),
        (1.0, -1.0, 1.0, -1.0, 2.0),
        (0.5, 0.5, 0.5, 0.5, 1.0),
        (10.0, -15.0, 6.0, 0.0, 2.0),
        (3.0, -2.0, 1.0, -0.5, 0.5),
        (1.0, 1.0, 1.0, 1.0, 1.0),
        (5.0, -10.0, 5.0, -1.0, 1.0),
    ]
    edges = [
        (0.0, 0.0, 0.0, 0.0, 0.0),
        (0.0, 0.0, 0.0, 0.0, 1.0),
        (0.0, 0.0, 1.0, 0.0, 0.0),
        (1.0, 0.0, 0.0, 0.0, 3.0),
        (0.0, 1.0, 0.0, 0.0, -2.0),
        (-2.0, 4.0, -2.0, 0.0, 2.0),
        (1.0, -3.0, 3.0, -1.0, 1.0),
        (1.0, 0.0, -1.0, 0.0, 1.0),
    ]
    if i < 10:
        return general[i]
    if i < 18:
        return edges[i - 10]
    return (
        float((i % 5) + 1),
        float(((i + 1) % 5) - 2),
        float(((i + 2) % 5) - 2),
        float(((i + 3) % 5) - 2),
        1.0 + (i / 10.0),
    )


def residual(a0: float, a1: float, a2: float, a3: float, x: float) -> float:
    return abs(a0 + a1 * x + a2 * x * x + a3 * x * x * x)


def choose_fixed_root(i: int) -> int:
    a0, a1, a2, a3, x0 = case_params(i)
    exp = expected_root(a0, a1, a2, a3, x0)
    lo = -(1 << (WIDTH - 1))
    hi = (1 << (WIDTH - 1)) - 1
    candidates = []
    for fixed in range(max(lo, int(math.floor((exp - EPSILON) * (1 << FRAC))) - 2),
                       min(hi, int(math.ceil((exp + EPSILON) * (1 << FRAC))) + 2) + 1):
        x = fixed / float(1 << FRAC)
        root_err = abs(x - exp)
        if root_err <= EPSILON + 1e-12:
            fx = residual(a0, a1, a2, a3, x)
            if i in SKIP_RESIDUAL_CASES or fx <= EPSILON + 1e-12:
                candidates.append((fx, root_err, fixed))
    if not candidates:
        raise RuntimeError(f"no fixed root can satisfy repaired case {i}")
    candidates.sort()
    return candidates[0][2]


def signed_literal(value: int) -> str:
    if value < 0:
        return f"-16'sd{abs(value)}"
    return f"16'sd{value}"


def oracle_verilog(roots: list[int]) -> str:
    cases = "\n".join(
        f"      6'd{i}: root_value = {signed_literal(root)};" for i, root in enumerate(roots)
    )
    return f"""`timescale 1ns/1ps

module newton_raphson_poly_fixedpoint #(
    parameter WIDTH = 16,
    parameter FRAC = 8,
    parameter MAX_ITER = 50
) (
    input clk,
    input rst,
    input start,
    input signed [WIDTH-1:0] x_init,
    input signed [WIDTH-1:0] coeff0,
    input signed [WIDTH-1:0] coeff1,
    input signed [WIDTH-1:0] coeff2,
    input signed [WIDTH-1:0] coeff3,
    output reg signed [WIDTH-1:0] root,
    output reg ready,
    output reg valid
);
  reg [5:0] case_idx = 0;

  function signed [WIDTH-1:0] root_value;
    input [5:0] idx;
    begin
      case (idx)
{cases}
        default: root_value = 16'sd0;
      endcase
    end
  endfunction

  always @(posedge clk) begin
    if (rst) begin
      ready <= 1'b0;
      valid <= 1'b0;
      root <= 0;
    end else if (start) begin
      root <= root_value(case_idx);
      ready <= 1'b1;
      valid <= 1'b1;
      case_idx <= case_idx + 1'b1;
    end
  end
endmodule
"""


def main() -> None:
    if not FIXTURE.exists():
        raise SystemExit(f"missing fixture: {FIXTURE}")
    if OUT_ROOT.exists():
        shutil.rmtree(OUT_ROOT)
    shutil.copytree(FIXTURE, OUT_ROOT)

    roots = [choose_fixed_root(i) for i in range(50)]
    (OUT_ROOT / "oracle_dut.v").write_text(oracle_verilog(roots), encoding="utf-8")
    (OUT_ROOT / "oracle_roots.json").write_text(
        json.dumps(
            {
                "width": WIDTH,
                "frac": FRAC,
                "skipped_residual_cases": sorted(SKIP_RESIDUAL_CASES),
                "roots": roots,
            },
            indent=2,
        )
        + "\n",
        encoding="utf-8",
    )

    compile_cmd = [
        "iverilog",
        "-g2012",
        "-o",
        str(OUT_ROOT / "sim.vvp"),
        str(OUT_ROOT / "tb.v"),
        str(OUT_ROOT / "oracle_dut.v"),
    ]
    compile_result = subprocess.run(
        compile_cmd,
        cwd=OUT_ROOT,
        capture_output=True,
        text=True,
        encoding="utf-8",
        errors="replace",
    )
    if compile_result.returncode != 0:
        raise SystemExit(compile_result.stderr)

    sim_result = subprocess.run(
        ["vvp", str(OUT_ROOT / "sim.vvp")],
        cwd=OUT_ROOT,
        capture_output=True,
        text=True,
        encoding="utf-8",
        errors="replace",
        timeout=120,
    )
    output = sim_result.stdout + sim_result.stderr
    (OUT_ROOT / "sim_output.log").write_text(output, encoding="utf-8")
    pass_count = len(re.findall(r"\bPASS\b", output))
    fail_count = len(re.findall(r"\bFAIL\b", output))
    skip_count = output.count("SKIP_REPAIRED_CONTRACT")
    summary = {
        "status": "pass" if sim_result.returncode == 0 and pass_count == 97 and fail_count == 0 and skip_count == 3 else "fail",
        "returncode": sim_result.returncode,
        "pass_count": pass_count,
        "fail_count": fail_count,
        "skip_count": skip_count,
        "expected_pass_count": 97,
        "expected_skip_count": 3,
    }
    sim_binary = OUT_ROOT / "sim.vvp"
    if sim_binary.exists():
        sim_binary.unlink()
    (OUT_ROOT / "validation_results.json").write_text(json.dumps(summary, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(summary, indent=2))
    if summary["status"] != "pass":
        raise SystemExit(1)


if __name__ == "__main__":
    main()
