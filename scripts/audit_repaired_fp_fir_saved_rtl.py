#!/usr/bin/env python3
"""Replay saved repaired FP-FIR RTL with a tight, exact-length FP32 oracle.

The released FP-FIR comparator used an absolute tolerance of 1.0, which is
larger than every expected output.  This audit never modifies the benchmark
fixtures: it copies each fixture to a temporary directory and injects a
strict contract there before replaying saved RTL.
"""

from __future__ import annotations

import argparse
import json
import os
import shutil
import sys
import tempfile
from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from cegis.tdes.fpga.autonomous.orchestrator import read_benchmark
from cegis.tdes.fpga.autonomous.run_aaai import _prepare_data_dir, _simulate_golden


DESIGNS = ("fp_band_pass_fir", "fp_high_pass_fir", "fp_low_pass_fir")


def find_design_dir(benchmark_root: Path, design: str) -> Path | None:
    for level in range(2, 7):
        candidate = benchmark_root / f"level-{level}" / design
        if candidate.is_dir():
            return candidate
    return None


def infer_design(path: Path) -> str | None:
    return next((part for part in path.parts if part in DESIGNS), None)


def expected_count(design_dir: Path) -> int:
    value = json.loads(
        (design_dir / "outputs" / "golden_output.json").read_text(encoding="utf-8")
    )
    if isinstance(value, dict):
        value = value.get("C", next(iter(value.values())))
    if value and isinstance(value[0], list):
        value = [item for row in value for item in row]
    return len(value)


def replay_one(result_path: Path, benchmark_root: Path, tolerance: float) -> dict:
    result = json.loads(result_path.read_text(encoding="utf-8", errors="replace"))
    design = infer_design(result_path)
    if design is None:
        raise ValueError("could not infer FP-FIR design from result path")
    source_fixture = find_design_dir(benchmark_root, design)
    if source_fixture is None:
        raise ValueError(f"fixture not found for {design}")

    verilog_dir = result_path.parent / "verilog"
    modules = {
        source.stem: source.read_text(encoding="utf-8", errors="replace")
        for source in sorted(verilog_dir.glob("*.v"))
    }
    if not modules:
        raise ValueError("no saved Verilog sources")

    total = expected_count(source_fixture)
    with tempfile.TemporaryDirectory(prefix="fp_fir_strict_fixture_") as temp:
        fixture = Path(temp) / design
        shutil.copytree(source_fixture, fixture)
        (fixture / "golden_contract.json").write_text(
            json.dumps(
                {"mode": "fp32", "absolute_tolerance": tolerance}, indent=2
            ),
            encoding="utf-8",
        )
        _, _, testbench = read_benchmark(str(fixture))
        data_dir = _prepare_data_dir(str(fixture))
        if data_dir is None:
            raise ValueError("copied fixture has no file-output data directory")
        correct, scored_total, detail = _simulate_golden(
            modules, testbench, data_dir, timeout=180
        )

    if scored_total <= 0:
        scored_total = total
    old_correct = result.get("golden_correct", result.get("best_passes"))
    old_total = result.get("golden_total", result.get("total_tests"))
    return {
        "result_path": str(result_path.relative_to(ROOT)).replace(os.sep, "/"),
        "design": design,
        "condition": result.get("condition"),
        "model": result.get("model"),
        "seed": result.get("seed"),
        "reported_correct": old_correct,
        "reported_total": old_total,
        "tight_correct": int(correct),
        "tight_total": int(scored_total),
        "tight_solved": bool(scored_total > 0 and correct == scored_total),
        "absolute_tolerance": tolerance,
        "exact_length_required": True,
        "finite_fp32_required": True,
        "detail": detail,
    }


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--artifact-root", type=Path, default=ROOT / "artifacts" / "raw_runs"
    )
    parser.add_argument(
        "--benchmark-root",
        type=Path,
        default=ROOT / "artifacts" / "benchmark_contracts" / "archxbench_repaired",
    )
    parser.add_argument("--tolerance", type=float, default=1e-6)
    parser.add_argument("--parallel", type=int, default=3)
    parser.add_argument(
        "--output",
        type=Path,
        default=ROOT
        / "artifacts"
        / "contract_validation"
        / "fp_fir_saved_rtl_tight_20260716"
        / "audit.json",
    )
    parser.add_argument(
        "--no-write-sidecars",
        action="store_true",
        help="do not replace adjacent strict_audit.json files with tight scores",
    )
    args = parser.parse_args()

    # Only repaired-contract runs are relevant.  Original-contract runs used a
    # different, known-invalid testbench and must not be silently conflated.
    paths = sorted(
        path
        for path in args.artifact_root.rglob("result.json")
        if "repaired" in str(path).lower() and infer_design(path) is not None
    )

    rows: list[dict] = []
    errors: list[dict] = []
    with ThreadPoolExecutor(max_workers=max(1, args.parallel)) as executor:
        futures = {
            executor.submit(
                replay_one, path, args.benchmark_root.resolve(), args.tolerance
            ): path
            for path in paths
        }
        for future in as_completed(futures):
            path = futures[future]
            try:
                row = future.result()
                rows.append(row)
                status = "PASS" if row["tight_solved"] else "FAIL"
                print(
                    f"{status} {row['design']} {row['condition']} seed={row['seed']}: "
                    f"{row['tight_correct']}/{row['tight_total']}"
                )
            except Exception as exc:
                errors.append(
                    {
                        "result_path": str(path.relative_to(ROOT)).replace(os.sep, "/"),
                        "error": str(exc),
                    }
                )
                print(f"ERROR {path}: {exc}")

    rows.sort(key=lambda row: (row["design"], str(row["condition"]), row["seed"] or -1))
    payload = {
        "verifier": "tight-fp32-exact-length-v1",
        "absolute_tolerance": args.tolerance,
        "benchmark_root": str(args.benchmark_root.resolve()),
        "artifact_selection": "result.json under a path containing 'repaired'",
        "results": rows,
        "errors": errors,
        "summary": {
            "artifacts": len(paths),
            "solved": sum(row["tight_solved"] for row in rows),
            "failed": sum(not row["tight_solved"] for row in rows),
            "errors": len(errors),
        },
    }
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(payload, indent=2), encoding="utf-8")
    if not args.no_write_sidecars:
        for row in rows:
            result_path = ROOT / Path(row["result_path"])
            sidecar = {
                "design": row["design"],
                "condition": row["condition"],
                "model": row["model"],
                "seed": row["seed"],
                "strict_correct": row["tight_correct"],
                "strict_total": row["tight_total"],
                "strict_solved": row["tight_solved"],
                "verifier_version": "tight-fp32-exact-length-v1",
                "benchmark_root": str(args.benchmark_root.resolve()),
                "absolute_tolerance": args.tolerance,
                "detail": row["detail"],
            }
            (result_path.parent / "strict_audit.json").write_text(
                json.dumps(sidecar, indent=2), encoding="utf-8"
            )
    print(json.dumps(payload["summary"], sort_keys=True))
    print(args.output)
    if errors:
        raise SystemExit(2)


if __name__ == "__main__":
    main()
