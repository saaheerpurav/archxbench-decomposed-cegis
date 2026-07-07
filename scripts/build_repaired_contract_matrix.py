"""Build the repaired-contract run matrix.

This is intentionally separate from `run_matrix_l3_l6.csv`. Repaired-contract
runs use modified executable benchmark contracts and must not be merged into
original ArchXBench solve-rate tables.
"""

from __future__ import annotations

import csv
import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
ARTIFACTS = ROOT / "artifacts"
OUT = ARTIFACTS / "inventories" / "repaired_contract_run_matrix.csv"
CONDITIONS = ["C2g", "C4i", "C4tl"]


def score(data: dict) -> str:
    passes = data.get("best_passes")
    total = data.get("total_tests")
    if passes is None or total is None:
        return ""
    return f"{passes}/{total}"


def golden_score(data: dict) -> str:
    correct = data.get("golden_correct")
    total = data.get("golden_total")
    if correct is None or total is None:
        return ""
    return f"{correct}/{total}"


def strict_clean(data: dict) -> bool:
    try:
        correct = int(data.get("golden_correct"))
        total = int(data.get("golden_total"))
    except (TypeError, ValueError):
        correct = 0
        total = 0
    if total > 0:
        return correct == total

    try:
        passes = int(data.get("best_passes"))
        tests = int(data.get("total_tests"))
    except (TypeError, ValueError):
        return False
    return bool(data.get("solved")) and tests > 0 and passes == tests


def seed_sort_key(seed: str) -> tuple[int, str]:
    try:
        return (0, f"{int(seed):020d}")
    except ValueError:
        return (1, seed)


def summarize(items: list[dict]) -> dict[str, str]:
    seeds = sorted({item["seed"] for item in items}, key=seed_sort_key)
    clean = sorted({item["seed"] for item in items if item["strict_clean"]}, key=seed_sort_key)
    scores = sorted({item["score"] for item in items if item["score"]})
    golden = sorted({item["golden"] for item in items if item["golden"]})
    return {
        "runs": str(len(seeds)),
        "clean_solves": str(len(clean)),
        "seeds_run": ",".join(seeds),
        "clean_seeds": ",".join(clean),
        "scores": ";".join(scores),
        "golden_scores": ";".join(golden),
        "llm_calls": ";".join(str(item["llm_calls"]) for item in items if item["llm_calls"] != ""),
        "wall_seconds": ";".join(str(item["wall_seconds"]) for item in items if item["wall_seconds"] != ""),
    }


def collect() -> list[dict]:
    rows: list[dict] = []
    for result_path in ARTIFACTS.rglob("result.json"):
        rel_parts = result_path.relative_to(ROOT).parts
        run_names = [
            part
            for part in rel_parts
            if part.startswith(("repaired_contracts_", "repaired_fir_", "repaired_fp_fir_"))
        ]
        if not run_names:
            continue
        try:
            data = json.loads(result_path.read_text(encoding="utf-8", errors="replace"))
        except json.JSONDecodeError:
            continue

        condition = str(data.get("condition") or "")
        if condition not in CONDITIONS:
            continue
        seed = str(data.get("seed") or "")
        rows.append(
            {
                "contract_run": run_names[0],
                "design": str(data.get("design") or ""),
                "condition": condition,
                "seed": seed,
                "strict_clean": strict_clean(data),
                "score": score(data),
                "golden": golden_score(data),
                "llm_calls": data.get("llm_calls", ""),
                "wall_seconds": data.get("wall_seconds", ""),
            }
        )
    return rows


def main() -> None:
    results = collect()
    run_names = sorted({row["contract_run"] for row in results})
    matrix_rows: list[dict[str, str]] = []

    for run_name in run_names:
        designs = sorted({row["design"] for row in results if row["contract_run"] == run_name})
        for design in designs:
            row: dict[str, str] = {"contract_run": run_name, "design": design}
            for condition in CONDITIONS:
                items = [
                    item
                    for item in results
                    if item["contract_run"] == run_name
                    and item["design"] == design
                    and item["condition"] == condition
                ]
                summary = summarize(items)
                prefix = condition.lower()
                for key, value in summary.items():
                    row[f"{prefix}_{key}"] = value
            matrix_rows.append(row)

    fieldnames = ["contract_run", "design"]
    for condition in CONDITIONS:
        prefix = condition.lower()
        fieldnames.extend(
            [
                f"{prefix}_runs",
                f"{prefix}_clean_solves",
                f"{prefix}_seeds_run",
                f"{prefix}_clean_seeds",
                f"{prefix}_scores",
                f"{prefix}_golden_scores",
                f"{prefix}_llm_calls",
                f"{prefix}_wall_seconds",
            ]
        )

    OUT.parent.mkdir(parents=True, exist_ok=True)
    with OUT.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(matrix_rows)
    print(f"Wrote {OUT.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
