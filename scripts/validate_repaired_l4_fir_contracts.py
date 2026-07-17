"""Independently validate the repaired Level-4 FIR numeric contracts.

The released coefficients are signed Q15 integers.  This validator parses the
public coefficient list and released JSON data, evaluates causal convolution,
and proves that arithmetic normalization by 2**15 reproduces every golden
sample.  It also records the failure rate of the stale 2**20 normalization so
the repair is falsifiable rather than a prompt-only assertion.
"""

from __future__ import annotations

import json
import re
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[1]
FIXTURE_ROOT = (
    REPO_ROOT
    / "artifacts"
    / "benchmark_contracts"
    / "archxbench_repaired"
    / "level-4"
)
OUT_ROOT = REPO_ROOT / "artifacts" / "contract_validation" / "l4_fir_q15_20260716"
DESIGNS = ("band_pass_fir", "high_pass_fir", "low_pass_fir")


def load_int_list(path: Path) -> list[int]:
    data = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(data, list) or not all(isinstance(item, int) for item in data):
        raise ValueError(f"expected a flat integer JSON list: {path}")
    return data


def parse_coefficients(spec: str) -> list[int]:
    match = re.search(r"h\[0\.\.100\]\s*=\s*\[(.*?)\]", spec, re.DOTALL)
    if match is None:
        raise ValueError("could not find public h[0..100] coefficient list")
    coefficients = [int(item) for item in re.findall(r"-?\d+", match.group(1))]
    if len(coefficients) != 101:
        raise ValueError(f"expected 101 coefficients, found {len(coefficients)}")
    return coefficients


def causal_fir(stimuli: list[int], coefficients: list[int], shift: int) -> list[int]:
    history: list[int] = []
    outputs: list[int] = []
    for sample in stimuli:
        history.insert(0, sample)
        del history[len(coefficients) :]
        accumulator = sum(coeff * history[index] for index, coeff in enumerate(coefficients[: len(history)]))
        outputs.append(accumulator >> shift)
    return outputs


def validate_one(design: str) -> dict:
    fixture = FIXTURE_ROOT / design
    spec = (fixture / "design-specs.txt").read_text(encoding="utf-8", errors="strict")
    coefficients = parse_coefficients(spec)
    stimuli = load_int_list(fixture / "inputs" / "stimuli.json")
    golden = load_int_list(fixture / "outputs" / "golden_output.json")
    q15 = causal_fir(stimuli, coefficients, 15)
    stale_q20 = causal_fir(stimuli, coefficients, 20)

    q15_matches = sum(actual == expected for actual, expected in zip(q15, golden))
    q20_within_tolerance = sum(abs(actual - expected) <= 1 for actual, expected in zip(stale_q20, golden))
    spec_is_q15 = (
        "arithmetic right-shift by 15" in spec
        and "right-shift by 20" not in spec
    )
    selfcheck_exists = (fixture / "tb_selfcheck.v").is_file()
    stale_testbenches = sorted(path.name for path in fixture.glob("tb_*_fir.v"))
    status = "pass" if (
        len(stimuli) == len(golden) == 1000
        and q15_matches == len(golden)
        and q20_within_tolerance < len(golden)
        and spec_is_q15
        and selfcheck_exists
        and not stale_testbenches
    ) else "fail"
    return {
        "design": design,
        "status": status,
        "stimulus_count": len(stimuli),
        "golden_count": len(golden),
        "coefficient_count": len(coefficients),
        "q15_exact_matches": q15_matches,
        "q20_within_one_lsb": q20_within_tolerance,
        "spec_is_q15": spec_is_q15,
        "selfcheck_exists": selfcheck_exists,
        "stale_file_output_testbenches": stale_testbenches,
    }


def main() -> int:
    OUT_ROOT.mkdir(parents=True, exist_ok=True)
    results = [validate_one(design) for design in DESIGNS]
    payload = {
        "status": "pass" if all(row["status"] == "pass" for row in results) else "fail",
        "normalization": "signed causal FIR accumulator arithmetic-shifted by 15 (Q15)",
        "results": results,
    }
    (OUT_ROOT / "validation_results.json").write_text(
        json.dumps(payload, indent=2) + "\n",
        encoding="utf-8",
    )
    print(json.dumps(payload, indent=2))
    return 0 if payload["status"] == "pass" else 1


if __name__ == "__main__":
    raise SystemExit(main())
