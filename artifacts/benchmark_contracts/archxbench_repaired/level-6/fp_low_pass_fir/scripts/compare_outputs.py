#!/usr/bin/env python3
"""Strict standalone comparison for the recovered FP low-pass fixture."""

import json
import math
import struct
from pathlib import Path


TOLERANCE = 1e-6


def fp32(item):
    if not isinstance(item, (str, int)) or isinstance(item, bool):
        raise ValueError(f"not an FP32 word: {item!r}")
    word = int(item, 16) if isinstance(item, str) else item
    if not 0 <= word <= 0xFFFFFFFF:
        raise ValueError(f"FP32 word out of range: {item!r}")
    value = struct.unpack("!f", struct.pack("!I", word))[0]
    if not math.isfinite(value):
        raise ValueError(f"non-finite FP32 value: {item!r}")
    return value


root = Path(__file__).resolve().parents[1]
golden = json.loads((root / "outputs" / "golden_output.json").read_text())
dut = json.loads((root / "outputs" / "dut_output.json").read_text())

if not isinstance(golden, list) or not isinstance(dut, list):
    raise SystemExit("[FAIL] Expected one-dimensional JSON lists")

mismatches = []
for index, (reference, candidate) in enumerate(zip(golden, dut)):
    try:
        error = abs(fp32(reference) - fp32(candidate))
    except ValueError as exc:
        mismatches.append((index, reference, candidate, str(exc)))
        continue
    if error > TOLERANCE:
        mismatches.append((index, reference, candidate, f"abs_error={error:.9g}"))

if len(dut) != len(golden) or mismatches:
    print(
        f"[FAIL] correct={len(golden) - len(mismatches) - max(0, len(golden) - len(dut))}/"
        f"{len(golden)} golden={len(golden)} dut={len(dut)} tolerance={TOLERANCE}"
    )
    for row in mismatches[:10]:
        print(f"  idx={row[0]} expected={row[1]!r} got={row[2]!r} {row[3]}")
    raise SystemExit(1)

print(f"[PASS] All {len(golden)} FP32 samples match within {TOLERANCE} with exact length")
