"""Replay the six previously claimed Harris cells under the exact repaired contract."""

from __future__ import annotations

import json
import shutil
import subprocess
import sys
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(REPO_ROOT))

from cegis.tdes.fpga.verilog_runner import find_tool


FIXTURE = (
    REPO_ROOT / "artifacts" / "benchmark_contracts" / "archxbench_repaired"
    / "level-5" / "harris_corner_detection"
)
OUT_ROOT = REPO_ROOT / "artifacts" / "contract_validation" / "harris_saved_rtl_exact_20260716"
SOURCES = {
    ("C2g", seed): (
        REPO_ROOT / "artifacts" / "raw_runs" / "c2g_artifact_collection_20260709_original"
        / "harris_corner_detection" / "C2g" / str(seed) / "verilog"
    )
    for seed in (42, 123, 456)
} | {
    ("C4i", seed): (
        REPO_ROOT / "artifacts" / "curated" / "main_claims" / "L5"
        / "harris_corner_detection" / "C4i" / "gpt-5.5" / str(seed) / "verilog"
    )
    for seed in (42, 123, 456)
}


def run_one(condition: str, seed: int, source: Path, iverilog: str, vvp: str, golden: list[int]) -> dict:
    work = OUT_ROOT / condition / str(seed)
    if work.exists():
        shutil.rmtree(work)
    shutil.copytree(FIXTURE, work)
    (work / "outputs" / "dut_output.json").unlink(missing_ok=True)
    rtl_files = sorted(source.glob("*.v"))
    if not rtl_files:
        return {"condition": condition, "seed": seed, "status": "missing_rtl", "source": str(source)}
    copied_rtl = []
    for rtl in rtl_files:
        destination = work / rtl.name
        shutil.copy2(rtl, destination)
        copied_rtl.append(destination.name)

    executable = work / "sim.vvp"
    compile_proc = subprocess.run(
        [iverilog, "-g2012", "-o", str(executable), "tb_harris_corner.v", *copied_rtl],
        cwd=work,
        capture_output=True,
        text=True,
        encoding="utf-8",
        errors="replace",
        timeout=120,
    )
    if compile_proc.returncode != 0:
        return {
            "condition": condition, "seed": seed, "status": "compile_failed",
            "detail": compile_proc.stdout + compile_proc.stderr,
        }
    sim_proc = subprocess.run(
        [vvp, str(executable)],
        cwd=work,
        capture_output=True,
        text=True,
        encoding="utf-8",
        errors="replace",
        timeout=240,
    )
    output = sim_proc.stdout + sim_proc.stderr
    (work / "sim_output.log").write_text(output, encoding="utf-8")
    dut_path = work / "outputs" / "dut_output.json"
    try:
        dut = json.loads(dut_path.read_text(encoding="utf-8"))
    except (FileNotFoundError, json.JSONDecodeError) as exc:
        return {
            "condition": condition, "seed": seed, "status": "invalid_output",
            "returncode": sim_proc.returncode, "detail": str(exc),
        }
    exact_matches = sum(actual == expected for actual, expected in zip(dut, golden))
    return {
        "condition": condition,
        "seed": seed,
        "status": "pass" if len(dut) == len(golden) and exact_matches == len(golden) else "fail",
        "returncode": sim_proc.returncode,
        "dut_count": len(dut),
        "golden_count": len(golden),
        "exact_matches": exact_matches,
        "mismatches": max(len(dut), len(golden)) - exact_matches,
    }


def main() -> int:
    OUT_ROOT.mkdir(parents=True, exist_ok=True)
    golden = json.loads((FIXTURE / "outputs" / "golden_output.json").read_text(encoding="utf-8"))
    iverilog = find_tool(["iverilog"])
    vvp = find_tool(["vvp"])
    if not iverilog or not vvp:
        raise SystemExit("Icarus Verilog toolchain is unavailable")
    with ThreadPoolExecutor(max_workers=3) as executor:
        futures = [
            executor.submit(run_one, condition, seed, source, iverilog, vvp, golden)
            for (condition, seed), source in SOURCES.items()
        ]
        rows = [future.result() for future in futures]
    rows.sort(key=lambda row: (row["condition"], row["seed"]))
    result = {
        "comparison": "exact binary equality and exact length",
        "parallelism": 3,
        "passes": sum(row["status"] == "pass" for row in rows),
        "total": len(rows),
        "results": rows,
    }
    (OUT_ROOT / "validation_results.json").write_text(
        json.dumps(result, indent=2) + "\n",
        encoding="utf-8",
    )
    print(json.dumps(result, indent=2))
    return 0 if result["passes"] == result["total"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
