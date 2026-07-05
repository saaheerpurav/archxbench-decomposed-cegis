"""Audit benchmark-contract issues for held-out ArchXBench rows.

This is a lightweight inventory for designs that should not be blindly counted
as paper claims: FIR-family rows and systolic_gemm.
"""

from __future__ import annotations

import csv
import json
import re
import struct
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[1]
ARCHX_ROOT = REPO_ROOT / "cegis" / "tdes" / "fpga" / "benchmarks" / "archxbench"
OUT_PATH = REPO_ROOT / "artifacts" / "inventories" / "holdout_contract_audit.csv"


ROWS = [
    ("L4", "level-4", "band_pass_fir"),
    ("L4", "level-4", "high_pass_fir"),
    ("L4", "level-4", "low_pass_fir"),
    ("L5", "level-5", "systolic_gemm"),
    ("L6", "level-6", "fp_band_pass_fir"),
    ("L6", "level-6", "fp_high_pass_fir"),
    ("L6", "level-6", "fp_low_pass_fir"),
]


def _text(path: Path) -> str:
    return path.read_text(encoding="utf-8", errors="ignore") if path.exists() else ""


def _hex_to_float(value: str) -> float:
    value_int = int(value, 16)
    return struct.unpack("!f", struct.pack("!I", value_int & 0xFFFFFFFF))[0]


def _fir_float_reference_status(design_dir: Path) -> str:
    tb_text = "\n".join(_text(path) for path in design_dir.glob("*.v"))
    coeff_hex = re.findall(r"coeffs\s*\[\s*\d+\s*\]\s*=\s*32'h([0-9a-fA-F]+)", tb_text)
    if not coeff_hex:
        return "no_coefficients_in_testbench"

    stimuli_path = design_dir / "inputs" / "stimuli.json"
    golden_path = design_dir / "outputs" / "golden_output.json"
    if not stimuli_path.exists() or not golden_path.exists():
        return "missing_stimuli_or_golden"

    stimuli = json.loads(stimuli_path.read_text(encoding="utf-8"))
    golden = json.loads(golden_path.read_text(encoding="utf-8"))
    coeffs = [_hex_to_float(item) for item in coeff_hex]
    samples = [_hex_to_float(item) for item in stimuli]
    golden_f = [_hex_to_float(item) for item in golden]

    outputs = []
    for idx in range(len(samples)):
        acc = 0.0
        for tap, coeff in enumerate(coeffs):
            if idx - tap >= 0:
                acc += samples[idx - tap] * coeff
        outputs.append(acc)
    diffs = [abs(ref - got) for ref, got in zip(golden_f, outputs)]
    return f"coeffs={len(coeffs)} max_abs_diff={max(diffs):.6g} mismatches_gt_1={sum(diff > 1.0 for diff in diffs)}"


def _classify(level: str, design: str, design_dir: Path) -> tuple[str, str]:
    specs = _text(design_dir / "design-specs.txt")
    tbs = list(design_dir.glob("*.v"))
    tb_text = "\n".join(_text(path) for path in tbs)

    if level == "L4" and design.endswith("_fir"):
        if "tb_selfcheck.v" in {path.name for path in tbs} and "benchmark repair" in specs.lower():
            return (
                "hold_repaired_style_in_source_tree",
                "L4 FIR source tree contains repaired-style selfcheck/spec text while stale JSON testbench remains; keep as diagnostic unless provenance is explicitly framed.",
            )
        return ("hold_unresolved", "L4 FIR contract needs manual review.")

    if design == "systolic_gemm":
        if "[PASS]" not in tb_text and "[FAIL]" not in tb_text:
            return (
                "repairable_display_only",
                "Original checker prints expected matrices but has no machine-readable PASS/FAIL; repaired contract can encode the printed expected values.",
            )
        return ("review", "Systolic checker has PASS/FAIL tokens; inspect before counting.")

    if design.startswith("fp_") and design.endswith("_fir"):
        fp_status = _fir_float_reference_status(design_dir)
        issues = []
        if "dut.coeffs" in tb_text:
            issues.append("hidden_dut_coeff_memory")
        if "stimuli_fp.json" in tb_text:
            issues.append("wrong_input_filename")
        if "lowpass_out_fp.json" in tb_text:
            issues.append("wrong_output_filename")
        if "fp_lowpass_fir_streaming" in specs and re.search(r"\bfp_lowpass_fir\b", tb_text):
            issues.append("module_name_mismatch")
        if "mismatches_gt_1=0" in fp_status:
            issues.append("loose_float_tolerance_masks_numeric_mismatch")
        return (
            "hold_unresolved_fp_fir_contract",
            "; ".join(issues + [fp_status]),
        )

    return ("review", "No classification rule matched.")


def main() -> None:
    rows = []
    for level, level_dir, design in ROWS:
        design_dir = ARCHX_ROOT / level_dir / design
        status, notes = _classify(level, design, design_dir)
        rows.append(
            {
                "level": level,
                "design": design,
                "status": status,
                "notes": notes,
                "path": str(design_dir.relative_to(REPO_ROOT)),
            }
        )

    OUT_PATH.parent.mkdir(parents=True, exist_ok=True)
    with OUT_PATH.open("w", newline="", encoding="utf-8") as fh:
        writer = csv.DictWriter(fh, fieldnames=["level", "design", "status", "notes", "path"])
        writer.writeheader()
        writer.writerows(rows)

    print(f"Wrote {OUT_PATH}")
    for row in rows:
        print(f"{row['level']} {row['design']}: {row['status']} - {row['notes']}")


if __name__ == "__main__":
    main()
