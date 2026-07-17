#!/usr/bin/env python3
"""Replay saved RTL and write strict verifier sidecars next to result.json.

This script never changes historical result.json files.  Matrix builders use
the adjacent strict_audit.json as the authoritative score when it is present.
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from cegis.tdes.fpga.autonomous.golden_compare import VERIFIER_VERSION
from cegis.tdes.fpga.autonomous.orchestrator import (
    _extract_top_module_name,
    read_benchmark,
)
from cegis.tdes.fpga.autonomous.run_aaai import (
    _count_tb_passes,
    _prepare_data_dir,
    _simulate_golden,
)
from cegis.tdes.fpga.verilog_runner import simulate


def find_design_dir(root: Path, design: str) -> Path | None:
    for level in range(2, 7):
        candidate = root / f"level-{level}" / design
        if candidate.is_dir():
            return candidate
    return None


def infer_design(result_path: Path, data: dict, benchmark_root: Path) -> str | None:
    design = str(data.get("design") or "")
    if design and find_design_dir(benchmark_root, design):
        return design
    for part in reversed(result_path.parts):
        if find_design_dir(benchmark_root, part):
            return part
    return None


def replay_one(result_path: Path, benchmark_root: Path) -> dict:
    data = json.loads(result_path.read_text(encoding="utf-8", errors="replace"))
    design = infer_design(result_path, data, benchmark_root)
    if not design:
        raise ValueError("could not infer design")
    design_dir = find_design_dir(benchmark_root, design)
    if design_dir is None:
        raise ValueError(f"design not found under benchmark root: {design}")

    verilog_dir = result_path.parent / "verilog"
    sources = {
        source.stem: source.read_text(encoding="utf-8", errors="replace")
        for source in sorted(verilog_dir.glob("*.v"))
    }
    if not sources:
        raise ValueError("no saved Verilog sources")

    _, design_specs, testbench = read_benchmark(str(design_dir))
    top_name = _extract_top_module_name(design_specs)
    fixture_data = _prepare_data_dir(str(design_dir))

    if fixture_data:
        correct, total, detail = _simulate_golden(
            sources, testbench, fixture_data, timeout=180,
        )
    else:
        sim = simulate(sources, testbench, timeout=180)
        if not sim.compiled:
            correct, total = 0, 1
            detail = f"compile failed: {sim.compile_error or sim.stderr}"
        else:
            correct, total = _count_tb_passes(sim.stdout)
            if total <= 0:
                correct, total = 0, 1
                detail = "testbench produced no PASS/FAIL evidence"
            else:
                detail = sim.stdout[-2000:]

    return {
        "design": design,
        "condition": data.get("condition"),
        "model": data.get("model"),
        "seed": data.get("seed"),
        "strict_correct": int(correct),
        "strict_total": int(total),
        "strict_solved": bool(total > 0 and correct == total),
        "verifier_version": VERIFIER_VERSION,
        "benchmark_root": str(benchmark_root.resolve()),
        "top_module": top_name,
        "detail": detail,
    }


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("artifact_roots", nargs="+", type=Path)
    parser.add_argument("--benchmark-root", required=True, type=Path)
    parser.add_argument("--designs", nargs="*")
    parser.add_argument("--conditions", nargs="*")
    parser.add_argument("--seeds", nargs="*", type=int)
    parser.add_argument("--claimed-solved-only", action="store_true")
    parser.add_argument("--no-write", action="store_true")
    args = parser.parse_args()

    requested_designs = set(args.designs or [])
    requested_conditions = set(args.conditions or [])
    requested_seeds = set(args.seeds or [])
    passed = failed = skipped = errors = 0

    result_paths: set[Path] = set()
    for root in args.artifact_roots:
        result_paths.update(root.rglob("result.json"))

    for result_path in sorted(result_paths):
        try:
            old = json.loads(result_path.read_text(encoding="utf-8", errors="replace"))
            design = infer_design(result_path, old, args.benchmark_root)
            if requested_designs and design not in requested_designs:
                skipped += 1
                continue
            if requested_conditions and str(old.get("condition")) not in requested_conditions:
                skipped += 1
                continue
            if requested_seeds and old.get("seed") not in requested_seeds:
                skipped += 1
                continue
            if args.claimed_solved_only and not old.get("solved"):
                skipped += 1
                continue
            audit = replay_one(result_path, args.benchmark_root)
            if not args.no_write:
                (result_path.parent / "strict_audit.json").write_text(
                    json.dumps(audit, indent=2), encoding="utf-8"
                )
            status = "PASS" if audit["strict_solved"] else "FAIL"
            print(
                f"{status} {result_path}: "
                f"{audit['strict_correct']}/{audit['strict_total']}"
            )
            if audit["strict_solved"]:
                passed += 1
            else:
                failed += 1
        except Exception as exc:
            errors += 1
            print(f"ERROR {result_path}: {exc}")

    print(
        f"Strict replay complete: pass={passed}, fail={failed}, "
        f"errors={errors}, skipped={skipped}"
    )
    if errors:
        raise SystemExit(2)


if __name__ == "__main__":
    main()
