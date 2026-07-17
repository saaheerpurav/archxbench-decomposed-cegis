#!/usr/bin/env python3
"""Audit the released ArchXBench FFT64 executable contract.

This does not invent an RTL numeric representation.  It verifies the coherent
parts of the release (the abstract complex DFT and FP32 mirror files) and emits
machine-readable evidence for the representation ambiguities that prevent an
acceptance-grade repaired fixture.
"""

from __future__ import annotations

import argparse
import cmath
import json
import math
import re
import struct
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
DEFAULT_SOURCE = (
    ROOT
    / "cegis"
    / "tdes"
    / "fpga"
    / "benchmarks"
    / "archxbench"
    / "level-6"
    / "fft_streaming_64pt"
)


def _load(path: Path) -> Any:
    with path.open("r", encoding="utf-8") as handle:
        return json.load(handle)


def _fp32_word(value: float) -> int:
    return struct.unpack(">I", struct.pack(">f", value))[0]


def _hex_word(value: str) -> int:
    return int(value, 16)


def _direct_dft(values: list[complex]) -> list[complex]:
    """Compute the mathematical DFT directly, independently of an FFT API."""

    n = len(values)
    return [
        sum(
            value * cmath.exp(-2j * math.pi * output_index * input_index / n)
            for input_index, value in enumerate(values)
        )
        for output_index in range(n)
    ]


def _round_nearest_away(value: float) -> int:
    if value >= 0:
        return math.floor(value + 0.5)
    return math.ceil(value - 0.5)


def _fixed_candidate(
    fractional_bits: int,
    inputs: list[complex],
    golden: list[complex],
) -> dict[str, Any]:
    scale = 1 << fractional_bits
    quantized_input = [
        complex(
            _round_nearest_away(value.real * scale),
            _round_nearest_away(value.imag * scale),
        )
        for value in inputs
    ]
    quantized_input_dft = _direct_dft(quantized_input)
    quantized_released_golden = [
        complex(
            _round_nearest_away(value.real * scale),
            _round_nearest_away(value.imag * scale),
        )
        for value in golden
    ]
    deltas = [
        max(abs(actual.real - expected.real), abs(actual.imag - expected.imag))
        for actual, expected in zip(
            quantized_input_dft, quantized_released_golden, strict=True
        )
    ]
    input_peak = max(
        max(abs(value.real), abs(value.imag)) for value in quantized_input
    )
    output_peak = max(
        max(abs(value.real), abs(value.imag)) for value in quantized_released_golden
    )
    return {
        "name": f"signed_Q{16 - fractional_bits}.{fractional_bits}",
        "fractional_bits": fractional_bits,
        "scale": scale,
        "input_peak_integer": int(input_peak),
        "input_fits_signed_16": input_peak <= (1 << 15) - 1,
        "output_peak_integer": int(output_peak),
        "output_fits_signed_20": output_peak <= (1 << 19) - 1,
        "first_nonzero_input_integer": int(quantized_input[1].real),
        "dc_output_integer": int(quantized_released_golden[0].real),
        "max_component_delta_between_dft_of_quantized_input_and_quantized_float_golden": max(
            deltas
        ),
    }


def audit(source: Path) -> dict[str, Any]:
    stimuli = _load(source / "inputs" / "stimuli.json")
    stimuli_hex = _load(source / "inputs" / "stimuli_hex.json")
    golden = _load(source / "outputs" / "golden_output.json")
    golden_hex = _load(source / "outputs" / "golden_output_hex.json")
    testbench = (source / "tb_fft_streaming_64pt.v").read_text(encoding="utf-8")
    specification = (source / "design-specs.txt").read_text(encoding="utf-8")

    expected_input_keys = ["real_in", "imag_in"]
    expected_output_keys = ["real_out", "imag_out"]
    assert list(stimuli) == expected_input_keys
    assert list(stimuli_hex) == expected_input_keys
    assert list(golden) == expected_output_keys
    assert list(golden_hex) == expected_output_keys
    assert all(len(stimuli[key]) == 64 for key in expected_input_keys)
    assert all(len(golden[key]) == 64 for key in expected_output_keys)

    input_values = [
        complex(real, imag)
        for real, imag in zip(
            stimuli["real_in"], stimuli["imag_in"], strict=True
        )
    ]
    golden_values = [
        complex(real, imag)
        for real, imag in zip(
            golden["real_out"], golden["imag_out"], strict=True
        )
    ]
    direct = _direct_dft(input_values)
    dft_errors = [
        max(abs(actual.real - expected.real), abs(actual.imag - expected.imag))
        for actual, expected in zip(direct, golden_values, strict=True)
    ]

    input_fp32_mismatches = sum(
        _fp32_word(float(stimuli[key][index]))
        != _hex_word(stimuli_hex[key][index])
        for key in expected_input_keys
        for index in range(64)
    )
    golden_fp32_mismatches = sum(
        _fp32_word(float(golden[key][index]))
        != _hex_word(golden_hex[key][index])
        for key in expected_output_keys
        for index in range(64)
    )

    data_w_match = re.search(r"parameter\s+DATA_W\s*=\s*(\d+)", testbench)
    growth_match = re.search(r"parameter\s+GROWTH\s*=\s*(\d+)", testbench)
    assert data_w_match and growth_match
    data_w = int(data_w_match.group(1))
    growth = int(growth_match.group(1))

    fixed_candidates = [
        _fixed_candidate(fractional_bits, input_values, golden_values)
        for fractional_bits in (13, 14)
    ]
    assert all(
        candidate["input_fits_signed_16"]
        and candidate["output_fits_signed_20"]
        for candidate in fixed_candidates
    )
    assert (
        fixed_candidates[0]["first_nonzero_input_integer"]
        != fixed_candidates[1]["first_nonzero_input_integer"]
    )

    observations = {
        "abstract_oracle": {
            "sample_count": 64,
            "direct_dft_max_component_error": max(dft_errors),
            "direct_dft_matches_released_float_golden_at_1e-12": max(dft_errors)
            <= 1e-12,
            "stimuli_hex_fp32_mismatch_count": input_fp32_mismatches,
            "golden_hex_fp32_mismatch_count": golden_fp32_mismatches,
        },
        "released_rtl_interface": {
            "input_width": data_w,
            "output_width": data_w + growth,
            "growth_bits": growth,
            "testbench_reads": "inputs/stimuli.json",
            "testbench_scan_format": "%d %d",
            "stimulus_json_schema": "object containing separate real_in and imag_in float arrays",
            "testbench_output_schema": "array of objects with real and imag integer fields",
            "golden_output_schema": "object containing separate real_out and imag_out float arrays",
            "flush_cycles": "$clog2(POINTS) = 6",
            "binary_point_or_fp_format_specified": bool(
                re.search(r"Q\d+\.\d+|binary point|fractional bits|IEEE-?754", specification, re.I)
            ),
        },
        "distinct_fixed_point_interpretations_that_both_fit_released_widths": fixed_candidates,
    }

    unresolved = [
        "No binary point or floating-point bit layout is specified for the 16-bit input and 20-bit output ports.",
        "The FP32 mirror files are internally valid but their 32-bit words cannot be applied to the released 16-bit ports without an unspecified conversion.",
        "At least Q3.13 and Q2.14 fit every released input and golden output but produce different integer stimuli and golden vectors.",
        "Input rounding, twiddle precision, per-stage rounding/saturation, and output error tolerance are unspecified.",
        "The testbench scans decimal integer pairs from a JSON object containing separate float arrays, so it does not apply the released samples as paired complex values.",
        "The testbench and golden output use incompatible JSON schemas.",
        "The testbench observes only six flush cycles although the specification leaves FFT pipeline latency open and allows architecture-dependent stage latency.",
    ]

    coherent_abstract_oracle = (
        observations["abstract_oracle"][
            "direct_dft_matches_released_float_golden_at_1e-12"
        ]
        and input_fp32_mismatches == 0
        and golden_fp32_mismatches == 0
    )
    assert coherent_abstract_oracle
    assert not observations["released_rtl_interface"][
        "binary_point_or_fp_format_specified"
    ]

    return {
        "design": "fft_streaming_64pt",
        "status": "HOLD_UNRESOLVED_RTL_NUMERIC_CONTRACT",
        "source": str(source.resolve()),
        "summary": (
            "The released floats define a coherent 64-point complex DFT, but "
            "the files do not uniquely map that oracle onto the released RTL ports."
        ),
        "observations": observations,
        "unresolved_ambiguities": unresolved,
        "safe_queue_action": "exclude; do not run or claim until an encoding and fixed-point arithmetic contract are externally specified",
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--source", type=Path, default=DEFAULT_SOURCE)
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()

    report = audit(args.source)
    rendered = json.dumps(report, indent=2, sort_keys=True) + "\n"
    if args.output:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(rendered, encoding="utf-8")
    print(rendered, end="")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
