#!/usr/bin/env python3
"""Audit ArchXBench file-output testbench contracts.

This identifies designs whose official testbench writes JSON output but does
not print native PASS/FAIL tokens. Those designs rely on post-simulation
golden comparison, so the runner must not gate golden verification on native
PASS/FAIL counts.
"""
from __future__ import annotations

import csv
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parent.parent
ARCHX_ROOT = REPO_ROOT / "cegis" / "tdes" / "fpga" / "benchmarks" / "archxbench"
OUT_PATH = REPO_ROOT / "artifacts" / "inventories" / "file_output_contract_audit.csv"


def _read_text(path: Path) -> str:
    return path.read_text(encoding="utf-8", errors="ignore")


def _golden_files(design_dir: Path) -> list[str]:
    outputs = design_dir / "outputs"
    if not outputs.is_dir():
        return []
    files = []
    for path in outputs.glob("*.json"):
        name = path.name.lower()
        if "golden" in name or "ref" in name:
            files.append(path.name)
    return sorted(files)


def _testbench_files(design_dir: Path) -> list[Path]:
    files = list(design_dir.glob("tb*.v")) + list(design_dir.glob("testbench*.v"))
    return sorted(set(files), key=lambda p: p.name)


def main() -> None:
    rows = []
    for level_dir in sorted(ARCHX_ROOT.glob("level-*")):
        if not level_dir.is_dir():
            continue
        for design_dir in sorted(level_dir.iterdir()):
            if not design_dir.is_dir():
                continue
            golden = _golden_files(design_dir)
            if not golden:
                continue

            tb_files = _testbench_files(design_dir)
            tb_text = "\n".join(_read_text(path) for path in tb_files)
            has_pass_fail = "PASS" in tb_text or "FAIL" in tb_text
            writes_dut_output = (
                "dut_output" in tb_text
                or "dut_dct" in tb_text
                or "dut_idct" in tb_text
                or "$fwrite" in tb_text
                or "$fdisplay" in tb_text
            )
            compare_script = design_dir / "scripts" / "compare_outputs.py"
            if writes_dut_output and not has_pass_fail:
                contract_class = "post_sim_golden_only"
                note = "testbench emits no native PASS/FAIL; golden JSON comparison is mandatory"
            else:
                contract_class = "native_or_dual_check"
                note = "native PASS/FAIL tokens exist; golden comparison may still be required for file-output rows"

            rows.append(
                {
                    "level": level_dir.name,
                    "design": design_dir.name,
                    "testbench_files": ";".join(path.name for path in tb_files),
                    "golden_files": ";".join(golden),
                    "writes_dut_output": str(writes_dut_output),
                    "has_native_pass_fail_tokens": str(has_pass_fail),
                    "has_compare_script": str(compare_script.exists()),
                    "contract_class": contract_class,
                    "note": note,
                }
            )

    OUT_PATH.parent.mkdir(parents=True, exist_ok=True)
    with OUT_PATH.open("w", newline="", encoding="utf-8") as fh:
        writer = csv.DictWriter(
            fh,
            fieldnames=[
                "level",
                "design",
                "testbench_files",
                "golden_files",
                "writes_dut_output",
                "has_native_pass_fail_tokens",
                "has_compare_script",
                "contract_class",
                "note",
            ],
        )
        writer.writeheader()
        writer.writerows(rows)

    print(f"Wrote {len(rows)} rows to {OUT_PATH}")
    risky = [row for row in rows if row["contract_class"] == "post_sim_golden_only"]
    print("Post-sim-golden-only designs:")
    for row in risky:
        print(f"- {row['level']}/{row['design']}")


if __name__ == "__main__":
    main()
