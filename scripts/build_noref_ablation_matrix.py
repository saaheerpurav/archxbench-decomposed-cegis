"""Build a separate inventory for C4 no-reference-source ablations.

The ``*-noRef`` conditions intentionally hide reference RTL from repair
prompts.  They are mechanism ablations, not aliases for the main C4i/C4tl
conditions, and therefore must never be folded into the original result
matrix.
"""

from __future__ import annotations

import csv
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from scripts import build_run_matrix


ARTIFACTS = ROOT / "artifacts"
OUT = ARTIFACTS / "inventories" / "noref_ablation_run_matrix.csv"
CONDITIONS = ("C4i-noRef", "C4tl-noRef")


def seed_sort_key(seed: str) -> tuple[int, str]:
    try:
        return (0, f"{int(seed):020d}")
    except ValueError:
        return (1, seed)


def collect() -> list[dict]:
    rows: list[dict] = []
    for result_path in ARTIFACTS.rglob("result.json"):
        rel_parts = result_path.relative_to(ROOT).parts
        if build_run_matrix.is_repaired_contract_path(rel_parts):
            continue
        try:
            data = json.loads(result_path.read_text(encoding="utf-8", errors="replace"))
        except json.JSONDecodeError:
            continue

        condition = str(data.get("condition") or "")
        if condition not in CONDITIONS:
            continue
        design = str(data.get("design") or "")
        model = build_run_matrix.normalized_model(data.get("model"))
        seed = str(data.get("seed") or "")
        audit = build_run_matrix.load_strict_audit(result_path)
        effective_data = data
        if audit is not None:
            effective_data = {
                **data,
                "golden_correct": audit["strict_correct"],
                "golden_total": audit["strict_total"],
                "solved": audit["strict_solved"],
            }
        rows.append(
            {
                "design": design,
                "condition": condition,
                "model": model,
                "seed": seed,
                "strict_clean": build_run_matrix.strict_clean(design, effective_data),
                "strict_audited": audit is not None,
                "score": build_run_matrix.score(data),
                "golden": build_run_matrix.golden_score(effective_data),
                "verification_source": "strict_audit" if audit else "result_json",
                "verifier_version": audit["verifier_version"] if audit else "",
                "artifact_path": result_path.as_posix(),
            }
        )

    canonical: dict[tuple[str, str, str, str], dict] = {}
    for row in rows:
        key = (row["design"], row["condition"], row["model"], row["seed"])
        rank = (
            1 if row["strict_audited"] else 0,
            1 if row["strict_clean"] else 0,
            row["artifact_path"],
        )
        old = canonical.get(key)
        if old is None:
            canonical[key] = row
            continue
        old_rank = (
            1 if old["strict_audited"] else 0,
            1 if old["strict_clean"] else 0,
            old["artifact_path"],
        )
        if rank > old_rank:
            canonical[key] = row
    return list(canonical.values())


def main() -> None:
    rows = collect()
    matrix_rows: list[dict[str, str]] = []
    groups = sorted({(r["design"], r["condition"], r["model"]) for r in rows})
    for design, condition, model in groups:
        items = [
            row
            for row in rows
            if row["design"] == design
            and row["condition"] == condition
            and row["model"] == model
        ]
        seeds = sorted({row["seed"] for row in items}, key=seed_sort_key)
        solved = sorted(
            {row["seed"] for row in items if row["strict_clean"]},
            key=seed_sort_key,
        )
        matrix_rows.append(
            {
                "design": design,
                "condition": condition,
                "model": model,
                "runs": len(seeds),
                "clean_solves": len(solved),
                "seeds_run": ",".join(seeds),
                "clean_seeds": ",".join(solved),
                "scores": ";".join(sorted({r["score"] for r in items if r["score"]})),
                "golden_scores": ";".join(
                    sorted({r["golden"] for r in items if r["golden"]})
                ),
                "verification_sources": ",".join(
                    sorted({r["verification_source"] for r in items})
                ),
                "verifier_versions": ",".join(
                    sorted({r["verifier_version"] for r in items if r["verifier_version"]})
                ),
            }
        )

    OUT.parent.mkdir(parents=True, exist_ok=True)
    fieldnames = [
        "design",
        "condition",
        "model",
        "runs",
        "clean_solves",
        "seeds_run",
        "clean_seeds",
        "scores",
        "golden_scores",
        "verification_sources",
        "verifier_versions",
    ]
    with OUT.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(matrix_rows)
    print(f"Wrote {OUT.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
