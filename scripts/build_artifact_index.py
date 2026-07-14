#!/usr/bin/env python3
"""Build the canonical artifact inventory from repo-local artifacts.

This repository treats artifacts/ as the only evidence roof. The generated
CSV/JSON indexes are derived from result.json files under artifacts/ and do
not depend on any external directory.
"""
from __future__ import annotations

import csv
import json
from pathlib import Path


ROOT = Path(__file__).resolve().parent.parent
ARTIFACTS = ROOT / "artifacts"
OUT_DIR = ARTIFACTS / "inventories"
CSV_PATH = OUT_DIR / "artifact_index.csv"
JSON_PATH = OUT_DIR / "artifact_index.json"

LEVELS = {"L1", "L2", "L3", "L4", "L5", "L6"}
CONDITIONS = {"C1", "C2g", "C4i", "C4i-randOrder", "C4tl", "C4a", "C4m", "C4"}


def rel(path: Path) -> str:
    return path.relative_to(ROOT).as_posix()


def path_part_after(parts: list[str], marker: str) -> str:
    try:
        return parts[parts.index(marker) + 1]
    except (ValueError, IndexError):
        return ""


def first_matching(parts: list[str], values: set[str]) -> str:
    for part in parts:
        if part in values:
            return part
    return ""


def find_seed(parts: list[str]) -> str:
    for part in reversed(parts):
        if part.isdigit():
            return part
    return ""


def score(data: dict) -> str:
    passes = data.get("best_passes")
    total = data.get("total_tests")
    if passes is None or total is None:
        return ""
    return f"{passes}/{total}"


def golden(data: dict) -> str:
    correct = data.get("golden_correct")
    total = data.get("golden_total")
    if correct is None or total is None:
        return ""
    if total == 0:
        return ""
    return f"{correct}/{total}"


def tier_for(path: Path) -> tuple[str, str]:
    rel_parts = rel(path).split("/")
    if "curated" in rel_parts:
        return "curated", path_part_after(rel_parts, "curated")
    if "raw_runs" in rel_parts:
        return "raw_runs", path_part_after(rel_parts, "raw_runs")
    if "metrics" in rel_parts:
        return "metrics", ""
    return "unknown", ""


def infer_design(parts: list[str], level: str, condition: str, seed: str) -> str:
    if level:
        i = parts.index(level)
        if i + 1 < len(parts):
            return parts[i + 1]

    if condition and condition in parts:
        i = parts.index(condition)
        # Raw run layouts vary. Prefer the part before condition when it is not
        # a model name, otherwise the part after model.
        if i > 0 and parts[i - 1] not in {"gpt-5.5", "gpt-4o", "o4-mini", "opus-4-6"}:
            return parts[i - 1]
        if i + 2 < len(parts):
            return parts[i + 2]

    if seed and seed in parts:
        i = parts.index(seed)
        if i > 0:
            return parts[i - 1]
    return ""


def row_for(result_path: Path) -> dict:
    data = json.loads(result_path.read_text(encoding="utf-8"))
    parts = rel(result_path.parent).split("/")

    roof, tier = tier_for(result_path)
    level = first_matching(parts, LEVELS)
    condition = data.get("condition") or first_matching(parts, CONDITIONS)
    seed = str(data.get("seed") or find_seed(parts))
    model = data.get("model") or ""
    design = data.get("design") or infer_design(parts, level, condition, seed)
    result_dir = result_path.parent

    return {
        "artifact_path": rel(result_path),
        "roof": roof,
        "tier": tier,
        "level": level or "mixed",
        "design": design,
        "condition": condition,
        "model": model,
        "seed": seed,
        "solved": str(data.get("solved", "")),
        "score": score(data),
        "golden": golden(data),
        "llm_calls": str(data.get("llm_calls", "")),
        "wall_seconds": str(data.get("wall_seconds", "")),
        "has_decomposition": str((result_dir / "decomposition.json").exists()),
        "verilog_files": str(len(list((result_dir / "verilog").glob("*.v"))) if (result_dir / "verilog").is_dir() else 0),
    }


def main() -> None:
    rows = [row_for(p) for p in sorted(ARTIFACTS.rglob("result.json"))]
    rows.sort(key=lambda r: (r["roof"], r["tier"], r["level"], r["design"], r["condition"], r["model"], r["seed"], r["artifact_path"]))

    OUT_DIR.mkdir(parents=True, exist_ok=True)
    fieldnames = [
        "artifact_path",
        "roof",
        "tier",
        "level",
        "design",
        "condition",
        "model",
        "seed",
        "solved",
        "score",
        "golden",
        "llm_calls",
        "wall_seconds",
        "has_decomposition",
        "verilog_files",
    ]

    with CSV_PATH.open("w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(rows)

    JSON_PATH.write_text(json.dumps(rows, indent=2), encoding="utf-8")
    print(f"Wrote {len(rows)} rows")
    print(rel(CSV_PATH))
    print(rel(JSON_PATH))


if __name__ == "__main__":
    main()
