"""Strict, contract-aware comparison for ArchXBench file outputs.

The released benchmarks use several incompatible JSON encodings.  Inferring
the numeric meaning of an integer from its Python type is unsafe: most designs
emit ordinary integers, while only the floating-point FIR fixtures encode
IEEE-754 words.  This module keeps that decision explicit and enforces exact
output cardinality for every contract.
"""

from __future__ import annotations

import json
import math
import struct
from pathlib import Path
from typing import Any, Literal


CompareMode = Literal["integer", "exact", "fp32"]
VERIFIER_VERSION = "strict-v2"


def _unwrap(value: Any, *, label: str) -> list[Any]:
    """Return the one-dimensional sample vector for a supported JSON schema."""
    if isinstance(value, dict):
        if "C" in value:
            value = value["C"]
        elif len(value) == 1:
            value = next(iter(value.values()))
        else:
            raise ValueError(
                f"{label}: ambiguous object schema; expected key 'C' or one key, "
                f"got {sorted(value)}"
            )

    if not isinstance(value, list):
        raise ValueError(f"{label}: expected a JSON list, got {type(value).__name__}")

    if value and isinstance(value[0], list):
        if any(not isinstance(row, list) for row in value):
            raise ValueError(f"{label}: mixed nested/non-nested list schema")
        value = [sample for row in value for sample in row]

    if any(isinstance(sample, (list, dict)) for sample in value):
        raise ValueError(f"{label}: unsupported nested sample schema")
    return value


def _as_integer(value: Any) -> int:
    if isinstance(value, bool):
        return int(value)
    if isinstance(value, int):
        return value
    if isinstance(value, float) and math.isfinite(value) and value.is_integer():
        return int(value)
    if isinstance(value, str):
        text = value.strip()
        try:
            return int(text, 0)
        except ValueError:
            if text and all(ch in "0123456789abcdefABCDEF" for ch in text):
                return int(text, 16)
    raise ValueError(f"not an integer sample: {value!r}")


def _as_fp32(value: Any) -> float:
    if isinstance(value, str):
        text = value.strip().lower()
        word = int(text, 16) if text.startswith("0x") else int(text, 16)
    elif isinstance(value, int) and not isinstance(value, bool):
        word = value
    else:
        raise ValueError(f"not an FP32 word: {value!r}")
    if not 0 <= word <= 0xFFFFFFFF:
        raise ValueError(f"FP32 word outside 32-bit range: {value!r}")
    result = struct.unpack("!f", struct.pack("!I", word))[0]
    if not math.isfinite(result):
        raise ValueError(f"non-finite FP32 sample: {value!r}")
    return result


def _exact_token(value: Any) -> Any:
    if isinstance(value, str):
        return value.strip().lower().removeprefix("0x")
    return value


def compare_values(
    golden: Any,
    dut: Any,
    *,
    mode: CompareMode,
    tolerance: float | None = None,
    label: str = "golden_output",
) -> tuple[int, int, str]:
    """Compare two decoded JSON values under an explicit numeric contract."""
    if tolerance is None:
        tolerance = 1.0 if mode in {"integer", "fp32"} else 0.0
    if not math.isfinite(tolerance) or tolerance < 0:
        return 0, 1, f"{label}: invalid comparison tolerance {tolerance!r}"
    try:
        expected = _unwrap(golden, label=f"{label} golden")
        actual = _unwrap(dut, label=f"{label} DUT")
    except ValueError as exc:
        return 0, 1, str(exc)

    total = len(expected)
    if total == 0:
        return 0, 1, f"{label}: golden output is empty"

    mismatches: list[tuple[int, Any, Any, str]] = []
    for index, (reference, candidate) in enumerate(zip(expected, actual)):
        try:
            if mode == "integer":
                matched = abs(_as_integer(reference) - _as_integer(candidate)) <= tolerance
            elif mode == "fp32":
                matched = abs(_as_fp32(reference) - _as_fp32(candidate)) <= tolerance
            elif mode == "exact":
                matched = _exact_token(reference) == _exact_token(candidate)
            else:  # defensive guard for callers not using the type annotation
                raise ValueError(f"unsupported comparison mode: {mode}")
            if not matched:
                mismatches.append((index, reference, candidate, "value mismatch"))
        except (TypeError, ValueError, OverflowError) as exc:
            mismatches.append((index, reference, candidate, str(exc)))

    missing = max(0, total - len(actual))
    extra = max(0, len(actual) - total)
    # Extra samples invalidate the contract but cannot make the number of
    # correct golden samples negative.  A solve additionally requires exact
    # length, expressed here by charging extras against the pass count.
    correct_pairs = total - len(mismatches) - missing
    passes = max(0, correct_pairs - extra)

    if not mismatches and missing == 0 and extra == 0:
        return total, total, f"{label}: PASS all {total} samples match exactly in length"

    lines = [
        f"{label}: FAIL ({passes}/{total} correct; golden={total}, DUT={len(actual)})"
    ]
    for index, reference, candidate, reason in mismatches[:10]:
        lines.append(
            f"  idx={index}: expected={reference!r} got={candidate!r} ({reason})"
        )
    if missing:
        lines.append(f"  missing {missing} DUT entries")
    if extra:
        lines.append(f"  unexpected {extra} extra DUT entries")
    return passes, total, "\n".join(lines)


def _load(path: Path) -> Any:
    with path.open(encoding="utf-8") as handle:
        return json.load(handle)


def _mode_for_design(design: str) -> CompareMode:
    # Harris is a binary classification mask.  A +/-1 integer tolerance would
    # make 0 and 1 indistinguishable and therefore accept an all-zero DUT.
    if design in {"aes_encryption", "aes_decryption", "harris_corner_detection"}:
        return "exact"
    if design in {"fp_band_pass_fir", "fp_high_pass_fir", "fp_low_pass_fir"}:
        return "fp32"
    return "integer"


def _contract_for_design(data: Path) -> tuple[CompareMode, float | None]:
    """Load an explicit copied-fixture contract, falling back to known releases."""
    contract_path = data / "golden_contract.json"
    if not contract_path.exists():
        return _mode_for_design(data.name), None
    contract = _load(contract_path)
    if not isinstance(contract, dict):
        raise ValueError("golden_contract.json must contain a JSON object")
    mode = contract.get("mode")
    if mode not in {"integer", "exact", "fp32"}:
        raise ValueError(f"unsupported golden contract mode: {mode!r}")
    tolerance = contract.get("absolute_tolerance")
    if tolerance is not None:
        tolerance = float(tolerance)
    return mode, tolerance


def compare_output_files(data_dir: str | Path, sim_workdir: str | Path) -> tuple[int, int, str]:
    """Load and compare all output files required by one benchmark fixture."""
    data = Path(data_dir)
    work = Path(sim_workdir)

    dct_pairs = [
        ("DCT", data / "outputs" / "golden_dct.json", work / "outputs" / "dut_dct.json"),
        ("IDCT", data / "outputs" / "golden_idct.json", work / "outputs" / "dut_idct.json"),
    ]
    if any(golden.exists() for _, golden, _ in dct_pairs):
        passes = 0
        total = 0
        details: list[str] = []
        for label, golden_path, dut_path in dct_pairs:
            if not golden_path.exists():
                total += 1
                details.append(f"{label}: golden output file not found")
                continue
            if not dut_path.exists():
                try:
                    _, missing_total, _ = compare_values(
                        _load(golden_path), [], mode="integer", label=label
                    )
                except (OSError, json.JSONDecodeError, ValueError):
                    missing_total = 1
                total += missing_total
                details.append(
                    f"{label}: DUT output file not written ({missing_total} expected samples)"
                )
                continue
            try:
                p, t, detail = compare_values(
                    _load(golden_path), _load(dut_path), mode="integer", label=label
                )
            except (OSError, json.JSONDecodeError, ValueError) as exc:
                p, t, detail = 0, 1, f"{label}: JSON parse error: {exc}"
            passes += p
            total += t
            details.append(detail)
        return passes, total, "\n\n".join(details)

    golden_path = data / "outputs" / "golden_output.json"
    dut_path = work / "outputs" / "dut_output.json"
    if not golden_path.exists():
        return 0, 1, "Golden output file not found"
    if not dut_path.exists():
        return 0, 1, "DUT output file not written"

    try:
        golden = _load(golden_path)
        dut = _load(dut_path)
    except (OSError, json.JSONDecodeError, ValueError) as exc:
        return 0, 1, f"JSON parse error: {exc}"
    try:
        mode, tolerance = _contract_for_design(data)
    except (OSError, json.JSONDecodeError, TypeError, ValueError) as exc:
        return 0, 1, f"Invalid golden contract metadata: {exc}"
    return compare_values(
        golden,
        dut,
        mode=mode,
        tolerance=tolerance,
        label="golden_output",
    )
