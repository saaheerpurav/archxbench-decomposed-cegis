#!/usr/bin/env python3
"""Run the post-audit ASP-DAC acceptance queue with bounded concurrency.

The queue is deliberately cell-specific: strict-replay solves are absent, so
resume/retry work cannot accidentally rerun a valid solved cell merely to
collect another artifact.
"""

from __future__ import annotations

import argparse
import json
import os
import sys
import threading
from concurrent.futures import ThreadPoolExecutor, as_completed
from dataclasses import asdict, dataclass
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))


@dataclass(frozen=True, order=True)
class Cell:
    design: str
    condition: str
    seed: int
    reason: str


def _add(cells: set[Cell], design: str, condition: str, seeds, reason: str) -> None:
    for seed in seeds:
        cells.add(Cell(design, condition, int(seed), reason))


def original_queue() -> list[Cell]:
    cells: set[Cell] = set()

    # Invalidated positive claims under the old integer-as-FP comparator.
    _add(cells, "conv2d", "C2g", (42, 123, 456), "invalidated integer golden score")
    _add(cells, "dct_idct_8pt_pipelined", "C2g", (42, 123, 456), "invalidated DCT/IDCT score")

    # C1 file-output pass@5 previously golden-checked only one compiling sample.
    for design in ("conv1d", "conv2d", "dct_idct_8pt_pipelined", "unsharp_mask"):
        _add(cells, design, "C1", (42, 123, 456), "corrected file-output pass@5")
    _add(cells, "aes_decryption", "C1", (42, 456), "complete corrected file-output pass@5")

    # Unsolved file-output cells receive strict feedback after verifier repair.
    for design in ("conv2d", "dct_idct_8pt_pipelined", "unsharp_mask"):
        _add(cells, design, "C4i", (42, 123, 456), "strict golden feedback")
    _add(cells, "conv1d", "C4tl", (123, 456), "C4tl file-output repair")
    for design in ("conv2d", "dct_idct_8pt_pipelined", "unsharp_mask"):
        _add(cells, design, "C4tl", (42, 123, 456), "C4tl strict scoring/final rescore")
    _add(cells, "aes_encryption", "C4tl", (42,), "remaining AES C4tl cell")
    _add(cells, "aes_decryption", "C4tl", (123, 456), "remaining AES C4tl cells")

    # High-probability self-checking near misses.
    _add(cells, "gauss_siedel", "C4tl", (42, 456), "47/50 and 49/50 near misses")

    # Targeted no-reference-source ablation for the core mechanism claims.
    for design in ("fft_16pt_iterative", "ifft_16pt_iterative"):
        _add(cells, design, "C4tl-noRef", (42, 123, 456), "oracle-exposure ablation")
    for design in ("fp_adder", "gauss_siedel", "gradient_descent"):
        _add(cells, design, "C4i-noRef", (42, 123, 456), "oracle-exposure ablation")
    for design in ("conv1d", "aes_encryption"):
        _add(cells, design, "C4tl-noRef", (42, 123, 456), "file-output oracle-exposure ablation")

    return sorted(cells)


def repaired_queue() -> list[Cell]:
    cells: set[Cell] = set()

    # Harris claims all fail exact binary replay on the repaired 128x128 contract.
    for condition in ("C2g", "C4i", "C4tl"):
        _add(cells, "harris_corner_detection", condition, (42, 123, 456), "exact binary Harris repair")

    _add(cells, "quantized_matmul", "C4tl", (42, 123, 456), "golden-only C4tl gate repair")
    _add(cells, "conv_3d", "C4i", (456,), "remaining repaired Conv3D C4i cell")
    _add(cells, "conv_3d", "C4tl", (42, 123, 456), "golden-only C4tl gate repair")

    _add(cells, "newton_raphson_polynomial", "C4i", (42, 123), "remaining repaired Newton cells")
    _add(cells, "newton_raphson_polynomial", "C4tl", (42, 123), "remaining repaired Newton cells")

    # The released FP FIRs used an absolute tolerance of 1.0, which accepts an
    # all-zero DUT, and the band/high fixtures exposed incorrect 31-tap lists
    # for 101-tap goldens.  Tight replay invalidated every historical claim, so
    # these are genuine contract-repair reruns rather than artifact reruns.
    for design in ("fp_band_pass_fir", "fp_high_pass_fir", "fp_low_pass_fir"):
        for condition in ("C2g", "C4i", "C4tl"):
            _add(cells, design, condition, (42, 123, 456), "recovered 101-tap FP32 contract")

    # Corrected Q15 L4 FIR fixture. Preserve historical valid C4i solves:
    # high-pass seed456 and low-pass seed123.
    for condition in ("C2g", "C4i", "C4tl"):
        _add(cells, "band_pass_fir", condition, (42, 123, 456), "corrected Q15 contract")
    _add(cells, "high_pass_fir", "C2g", (42, 123, 456), "corrected Q15 contract")
    _add(cells, "high_pass_fir", "C4i", (42, 123), "corrected Q15 contract")
    _add(cells, "high_pass_fir", "C4tl", (42, 123, 456), "corrected Q15 contract")
    _add(cells, "low_pass_fir", "C2g", (42, 123, 456), "corrected Q15 contract")
    _add(cells, "low_pass_fir", "C4i", (42, 456), "corrected Q15 contract")
    _add(cells, "low_pass_fir", "C4tl", (42, 123, 456), "corrected Q15 contract")

    return sorted(cells)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--queue", choices=("original", "repaired"), required=True)
    parser.add_argument("--benchmark-root", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--parallel", type=int, default=3)
    parser.add_argument("--model", default="gpt-5.5")
    parser.add_argument("--list", action="store_true")
    parser.add_argument("--rerun-failed", action="store_true")
    args = parser.parse_args()

    if args.parallel != 3:
        raise SystemExit("Acceptance queue is locked to --parallel 3")
    if args.model != "gpt-5.5":
        raise SystemExit("Acceptance queue is locked to Codex GPT-5.5")

    cells = original_queue() if args.queue == "original" else repaired_queue()
    print(f"Queue {args.queue}: {len(cells)} cells")
    for cell in cells:
        print(f"  {cell.design} {cell.condition} trial={cell.seed}: {cell.reason}")
    if args.list:
        return

    args.output.mkdir(parents=True, exist_ok=True)
    manifest_path = args.output / "queue_manifest.json"
    resume_history = []
    if manifest_path.exists():
        try:
            previous_manifest = json.loads(
                manifest_path.read_text(encoding="utf-8", errors="replace")
            )
        except json.JSONDecodeError:
            previous_manifest = {"error": "malformed prior manifest"}
        preexisting_cells = []
        for cell in cells:
            prior_result = (
                args.output / cell.design / cell.condition / str(cell.seed) / "result.json"
            )
            if prior_result.exists():
                preexisting_cells.append(
                    {"design": cell.design, "condition": cell.condition, "seed": cell.seed}
                )
        resume_history = list(previous_manifest.get("resume_history", []))
        resume_history.append(
            {
                "model": previous_manifest.get("model"),
                "reasoning_effort": previous_manifest.get("reasoning_effort", "unknown"),
                "codex_cli_timeout_seconds": previous_manifest.get(
                    "codex_cli_timeout_seconds"
                ),
                "completed_cells_preserved": preexisting_cells,
            }
        )
    manifest_path.write_text(
        json.dumps(
            {
                "queue": args.queue,
                "model": args.model,
                "parallel": args.parallel,
                "reasoning_effort": os.environ.get("CODEX_REASONING_EFFORT", "low"),
                "codex_cli_timeout_seconds": int(os.environ.get("CODEX_CLI_TIMEOUT", "900")),
                "benchmark_root": str(args.benchmark_root.resolve()),
                "resume_history": resume_history,
                "cells": [asdict(cell) for cell in cells],
            },
            indent=2,
        ),
        encoding="utf-8",
    )

    pending: list[Cell] = []
    for cell in cells:
        result_path = args.output / cell.design / cell.condition / str(cell.seed) / "result.json"
        if result_path.exists():
            try:
                old = json.loads(result_path.read_text(encoding="utf-8", errors="replace"))
            except json.JSONDecodeError:
                old = {"error": "malformed result"}
            if not old.get("error") or not args.rerun_failed:
                print(f"SKIP completed {cell.design}/{cell.condition}/{cell.seed}")
                continue
        pending.append(cell)

    print(f"Running {len(pending)} pending cells with parallel=3")
    if not pending:
        return

    # Set these before importing run_aaai because its benchmark paths are
    # initialized at module import time.
    os.environ["ARCHXBENCH_ROOT"] = str(args.benchmark_root.resolve())
    os.environ["USE_CODEX_CLI"] = "1"
    os.environ.setdefault("CODEX_REASONING_EFFORT", "low")
    os.environ.setdefault("CODEX_CLI_TIMEOUT", "1800")

    from cegis.tdes.fpga.autonomous.run_aaai import run_cell

    print_lock = threading.Lock()
    completed = 0
    solved = 0

    def execute(cell: Cell):
        return cell, run_cell(
            cell.design,
            cell.condition,
            args.model,
            cell.seed,
            "",
            "",
            str(args.output),
        )

    with ThreadPoolExecutor(max_workers=3) as executor:
        futures = {executor.submit(execute, cell): cell for cell in pending}
        for future in as_completed(futures):
            cell = futures[future]
            try:
                _, result = future.result()
            except Exception as exc:
                result = {"error": str(exc), "solved": False}
            completed += 1
            solved += int(bool(result.get("solved")))
            with print_lock:
                print(
                    f"DONE {completed}/{len(pending)} "
                    f"{cell.design}/{cell.condition}/{cell.seed}: "
                    f"{'SOLVED' if result.get('solved') else 'FAILED'} "
                    f"{result.get('best_passes', '?')}/{result.get('total_tests', '?')} "
                    f"error={result.get('error', '')}",
                    flush=True,
                )

    print(f"Queue complete: solved={solved}/{len(pending)}")


if __name__ == "__main__":
    main()
