"""Build the source-of-truth ArchXBench run matrix.

The matrix is intentionally derived from repo-local artifacts only. It does
not read old local folders or external repositories.
"""

from __future__ import annotations

import csv
import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
BENCH = ROOT / "cegis" / "tdes" / "fpga" / "benchmarks" / "archxbench"
ARTIFACTS = ROOT / "artifacts"
OUT = ARTIFACTS / "inventories" / "run_matrix_l3_l6.csv"

CONDITIONS = ["C1", "C2g", "C4i", "C4tl"]
MODEL_ALIASES = {
    "codex-gpt-5.5": "gpt-5.5",
    "o4mini": "o4-mini",
    "opus-4-6": "claude-opus-4-6",
}
FILE_OUTPUT_DESIGNS = {
    "conv1d",
    "conv2d",
    "dct_idct_8pt_pipelined",
    "harris_corner_detection",
    "systolic_gemm",
    "unsharp_mask",
    "aes_decryption",
    "aes_encryption",
    "conv_3d",
    "fft_streaming_64pt",
    "fp_band_pass_fir",
    "fp_high_pass_fir",
    "fp_low_pass_fir",
    "quantized_matmul",
}


def official_designs() -> list[tuple[str, str]]:
    rows: list[tuple[str, str]] = []
    for level_num in range(3, 7):
        level_dir = BENCH / f"level-{level_num}"
        if not level_dir.exists():
            continue
        for child in sorted(level_dir.iterdir()):
            if child.is_dir():
                rows.append((f"L{level_num}", child.name))
    return rows


def normalized_model(model: object) -> str:
    text = "" if model is None else str(model)
    return MODEL_ALIASES.get(text, text)


def normalized_condition(condition: object) -> str:
    text = "" if condition is None else str(condition)
    return "C2g" if text == "C2" else text


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


def strict_clean(design: str, data: dict) -> bool:
    if design in FILE_OUTPUT_DESIGNS:
        try:
            correct = int(data.get("golden_correct"))
            total = int(data.get("golden_total"))
        except (TypeError, ValueError):
            return False
        return total > 0 and correct == total

    try:
        passes = int(data.get("best_passes"))
        total = int(data.get("total_tests"))
    except (TypeError, ValueError):
        return False
    return bool(data.get("solved")) and total > 0 and passes == total


def infra_error(data: dict) -> bool:
    error = str(data.get("error") or "").lower()
    return (
        "charmap" in error
        or "codec can't encode" in error
        or "timed out after" in error
    )


def seed_sort_key(seed: str) -> tuple[int, str]:
    try:
        return (0, f"{int(seed):020d}")
    except ValueError:
        return (1, seed)


def summarize_group(items: list[dict]) -> dict[str, str]:
    seeds = sorted({str(item["seed"]) for item in items if item["seed"]}, key=seed_sort_key)
    clean_seeds = sorted(
        {str(item["seed"]) for item in items if item["seed"] and item["strict_clean"]},
        key=seed_sort_key,
    )
    best_scores = sorted({item["score"] for item in items if item["score"]})
    golden_scores = sorted({item["golden"] for item in items if item["golden"]})
    models = sorted({item["model"] for item in items if item["model"]})
    return {
        "runs": str(len(seeds)),
        "clean_solves": str(len(clean_seeds)),
        "seeds_run": ",".join(seeds),
        "clean_seeds": ",".join(clean_seeds),
        "models": ",".join(models),
        "scores": ";".join(best_scores),
        "golden_scores": ";".join(golden_scores),
    }


def collect_results() -> list[dict]:
    designs = {design: level for level, design in official_designs()}
    results: list[dict] = []
    for result_path in ARTIFACTS.rglob("result.json"):
        rel_parts = result_path.relative_to(ROOT).parts
        if any(part.startswith("repaired_contracts_") for part in rel_parts):
            continue
        try:
            data = json.loads(result_path.read_text(encoding="utf-8", errors="replace"))
        except json.JSONDecodeError:
            continue

        design = str(data.get("design") or "")
        if design not in designs:
            parts = set(result_path.parts)
            matches = [name for name in designs if name in parts]
            if not matches:
                continue
            design = matches[-1]

        condition = normalized_condition(data.get("condition"))
        if condition not in CONDITIONS:
            parts = set(result_path.parts)
            if "C2" in parts:
                condition = "C2g"
            else:
                matches = [name for name in CONDITIONS if name in parts]
                condition = matches[-1] if matches else condition
        if condition not in CONDITIONS:
            continue

        seed = data.get("seed")
        if seed is None:
            numeric_parts = [part for part in result_path.parts if part.isdigit()]
            seed = numeric_parts[-1] if numeric_parts else ""

        model = normalized_model(data.get("model"))
        is_strict_clean = strict_clean(design, data)
        results.append(
            {
                "level": designs[design],
                "design": design,
                "condition": condition,
                "model": model,
                "seed": str(seed),
                "strict_clean": is_strict_clean,
                "infra_error": infra_error(data),
                "score": score(data),
                "golden": golden_score(data),
                "artifact_path": result_path.as_posix(),
            }
        )

    # Canonicalize repeated attempts of the same design/condition/model/seed.
    # Old infrastructure-failure rows remain in the artifact index, but the run
    # matrix should describe the current canonical outcome for each seed.
    best: dict[tuple[str, str, str, str, str], dict] = {}
    for item in results:
        key = (
            item["level"],
            item["design"],
            item["condition"],
            item["model"],
            item["seed"],
        )

        def rank(row: dict) -> tuple[int, int, int, int, str]:
            golden = row["golden"]
            golden_total = 0
            if "/" in golden:
                try:
                    golden_total = int(golden.split("/", 1)[1])
                except ValueError:
                    golden_total = 0
            return (
                1 if row["strict_clean"] else 0,
                0 if row["infra_error"] else 1,
                1 if golden_total > 0 else 0,
                1 if row["score"] and row["score"] != "0/0" else 0,
                row["artifact_path"],
            )

        if key not in best or rank(item) > rank(best[key]):
            best[key] = item

    return list(best.values())


def main() -> None:
    results = collect_results()
    matrix_rows: list[dict[str, str]] = []

    for level, design in official_designs():
        row: dict[str, str] = {"level": level, "design": design}
        for condition in CONDITIONS:
            items = [
                item
                for item in results
                if item["level"] == level
                and item["design"] == design
                and item["condition"] == condition
                and item["model"] == "gpt-5.5"
            ]
            summary = summarize_group(items)
            prefix = condition.lower()
            for key, value in summary.items():
                row[f"{prefix}_{key}"] = value
        matrix_rows.append(row)

    fieldnames = ["level", "design"]
    for condition in CONDITIONS:
        prefix = condition.lower()
        fieldnames.extend(
            [
                f"{prefix}_runs",
                f"{prefix}_clean_solves",
                f"{prefix}_seeds_run",
                f"{prefix}_clean_seeds",
                f"{prefix}_models",
                f"{prefix}_scores",
                f"{prefix}_golden_scores",
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
