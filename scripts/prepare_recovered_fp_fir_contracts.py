"""Prepare all three independently recovered L6 floating-point FIR fixtures."""

from __future__ import annotations

import json
import shutil
from pathlib import Path

import prepare_recovered_fp_low_contract as low


REPO_ROOT = low.REPO_ROOT
SOURCE_LEVEL = low.SOURCE.parent
RECOVERED_ROOT = low.RECOVERED_ROOT


DESIGNS = {
    "fp_band_pass_fir": {
        "top": "fp_bandpass_fir",
        "tb": "tb_fp_band_pass_fir.v",
        "generator": "scipy.signal.firwin(101, [800, 3000], pass_zero=False, fs=50000)",
        "passband": "800--3000 Hz",
        "upstream_output": "bandpass_output.json",
        "upstream_float64_max_error": 4.440892098500626e-16,
        "source_sha256": {
            "inputs/stimuli.json": "ce6e83c694b4a09f49fe7acf84693198f10eceb2f853b7915b153b1a00cfebfc",
            "outputs/golden_output.json": "1299bc17f51148769cc556416353c96f6086a6fff4c9ad2d66fd22ef086bfe36",
        },
        "coefficient_words": [
            "39fd56aa", "39a77386", "39334aac", "386d8991", "b5a5aba3",
            "37bd8450", "391fc780", "39d475a3", "3a4d6269", "3aa61be3",
            "3aed3bf0", "3b192db6", "3b347633", "3b418ca6", "3b3a03d9",
            "3b193e82", "3abb6ece", "391fa206", "bab5ebf4", "bb45facc",
            "bb9488a1", "bbbaa786", "bbceb76a", "bbcc46b2", "bbb25119",
            "bb841b84", "bb12f16e", "b9e522de", "3a74a930", "3ab63a39",
            "3a034101", "bb0600e4", "bbd0625a", "bc49a519", "bc9f93b5",
            "bcdeddd2", "bd0dbce0", "bd2696ef", "bd35d6f1", "bd37d430",
            "bd29e7d2", "bd0adcc4", "bcb67535", "bbeaf5be", "3c2a8ac6",
            "3ceeaa3c", "3d42697f", "3d82ae39", "3d9d14a6", "3dadfa04",
            "3db3ca74", "3dadfa04", "3d9d14a6", "3d82ae39", "3d42697f",
            "3ceeaa3c", "3c2a8ac6", "bbeaf5be", "bcb67535", "bd0adcc4",
            "bd29e7d2", "bd37d430", "bd35d6f1", "bd2696ef", "bd0dbce0",
            "bcdeddd2", "bc9f93b5", "bc49a519", "bbd0625a", "bb0600e4",
            "3a034101", "3ab63a39", "3a74a930", "b9e522de", "bb12f16e",
            "bb841b84", "bbb25119", "bbcc46b2", "bbceb76a", "bbbaa786",
            "bb9488a1", "bb45facc", "bab5ebf4", "391fa206", "3abb6ece",
            "3b193e82", "3b3a03d9", "3b418ca6", "3b347633", "3b192db6",
            "3aed3bf0", "3aa61be3", "3a4d6269", "39d475a3", "391fc780",
            "37bd8450", "b5a5aba3", "386d8991", "39334aac", "39a77386",
            "39fd56aa",
        ],
    },
    "fp_high_pass_fir": {
        "top": "fp_highpass_fir",
        "tb": "tb_fp_high_pass_fir.v",
        "generator": "scipy.signal.firwin(101, 5000, pass_zero=False, fs=50000)",
        "passband": "above 5000 Hz",
        "upstream_output": "golden_output_fp.json",
        "upstream_float64_max_error": 4.996003610813204e-16,
        "source_sha256": {
            "inputs/stimuli.json": "ff35aed952d0a7ec3d07e622b655f6d64f8b659856c772211b114f94294462c9",
            "outputs/golden_output.json": "f8e8f3974dd2278ca98b0f9cfadce3737e73bd24e5b917917f4a8c16c45a4336",
        },
        "coefficient_words": [
            "21a5e407", "39a1fef1", "3a0a48e5", "3a14dc7c", "39c9729c",
            "21373cac", "b9fa686f", "ba647ae3", "ba815b49", "ba3564bc",
            "a2c126e6", "3a696787", "3ad5c178", "3af17343", "3aa82360",
            "239ded49", "bad3be22", "bb3f7379", "bb556676", "bb12a289",
            "a4439339", "3b33fb1e", "3ba0cd0c", "3bb13ea7", "3b71153f",
            "a30bf866", "bb915883", "bc00e7a5", "bc0d333a", "bbbf1429",
            "a3c43dcb", "3be4ec47", "3c4accff", "3c5e3e69", "3c16b483",
            "24c72eb7", "bc367814", "bca31ca3", "bcb4ed9c", "bc794bfe",
            "a403343e", "3c9e21ad", "3d1233f3", "3d2969d5", "3cf73d64",
            "240c9a35", "bd3cd9b8", "bdcd0395", "be1a7617", "be3f721e",
            "3f4cd56c", "be3f721e", "be1a7617", "bdcd0395", "bd3cd9b8",
            "240c9a35", "3cf73d64", "3d2969d5", "3d1233f3", "3c9e21ad",
            "a403343e", "bc794bfe", "bcb4ed9c", "bca31ca3", "bc367814",
            "24c72eb7", "3c16b483", "3c5e3e69", "3c4accff", "3be4ec47",
            "a3c43dcb", "bbbf1429", "bc0d333a", "bc00e7a5", "bb915883",
            "a30bf866", "3b71153f", "3bb13ea7", "3ba0cd0c", "3b33fb1e",
            "a4439339", "bb12a289", "bb556676", "bb3f7379", "bad3be22",
            "239ded49", "3aa82360", "3af17343", "3ad5c178", "3a696787",
            "a2c126e6", "ba3564bc", "ba815b49", "ba647ae3", "b9fa686f",
            "21373cac", "39c9729c", "3a14dc7c", "3a0a48e5", "39a1fef1",
            "21a5e407",
        ],
    },
}


def _verify(design: str, cfg: dict) -> dict[str, int | float]:
    source = SOURCE_LEVEL / design
    for relative, expected in cfg["source_sha256"].items():
        actual = low._sha256(source / relative)
        if actual != expected:
            raise RuntimeError(
                f"Refusing to recover changed {design}/{relative}: "
                f"expected {expected}, got {actual}"
            )

    stimuli_raw = json.loads((source / "inputs" / "stimuli.json").read_text())
    golden_raw = json.loads((source / "outputs" / "golden_output.json").read_text())
    coefficients = [low._fp32(word) for word in cfg["coefficient_words"]]
    stimuli = [low._fp32(item.removeprefix("0x")) for item in stimuli_raw]
    golden = [low._fp32(item.removeprefix("0x")) for item in golden_raw]
    if len(coefficients) != 101 or len(stimuli) != 1000 or len(golden) != 1000:
        raise RuntimeError(f"Unexpected recovered cardinality for {design}")

    predicted = []
    for sample_index in range(len(stimuli)):
        accumulator = low._round_fp32(0.0)
        for tap_index, coefficient in enumerate(coefficients):
            if sample_index < tap_index:
                break
            product = low._round_fp32(stimuli[sample_index - tap_index] * coefficient)
            accumulator = low._round_fp32(accumulator + product)
        predicted.append(accumulator)
    errors = [abs(reference - candidate) for reference, candidate in zip(golden, predicted)]
    if max(errors) > 1e-6 or max(errors[101:]) > 1e-6:
        raise RuntimeError(f"{design} failed recovered FP32 validation: {max(errors)}")
    return {
        "sample_count": len(golden),
        "tap_count": len(coefficients),
        "transient_identification_samples": 101,
        "holdout_samples": 899,
        "fp32_sequential_max_abs_error": max(errors),
        "fp32_sequential_holdout_max_abs_error": max(errors[101:]),
        "upstream_float64_max_abs_error": cfg["upstream_float64_max_error"],
        "maximum_golden_magnitude": max(abs(item) for item in golden),
    }


def _coefficient_spec(words: list[str]) -> str:
    return "\n".join(
        f"  h[{index:3d}] = 32'h{word};" for index, word in enumerate(words)
    )


def _stage(design: str, cfg: dict) -> dict[str, int | float]:
    source = SOURCE_LEVEL / design
    destination = RECOVERED_ROOT / "level-6" / design
    validation = _verify(design, cfg)
    if destination.exists():
        shutil.rmtree(destination)
    shutil.copytree(source, destination)

    testbench = low.TESTBENCH.replace("tb_lowpass_fir_fp", f"tb_{design}")
    testbench = testbench.replace("fp_lowpass_fir", cfg["top"])
    (destination / cfg["tb"]).write_text(testbench, encoding="utf-8")
    (destination / "scripts" / "compare_outputs.py").write_text(
        low.COMPARE_SCRIPT,
        encoding="utf-8",
    )
    (destination / "golden_contract.json").write_text(
        json.dumps(
            {
                "mode": "fp32",
                "absolute_tolerance": 1e-6,
                "require_exact_length": True,
                "require_finite": True,
            },
            indent=2,
        )
        + "\n",
        encoding="utf-8",
    )
    (destination / "recovered_fir_contract.json").write_text(
        json.dumps(
            {
                "tap_count": 101,
                "sample_rate_hz": 50000,
                "passband": cfg["passband"],
                "coefficient_generator": cfg["generator"],
                "coefficient_words_fp32": [
                    f"0x{word}" for word in cfg["coefficient_words"]
                ],
                "source_asset_sha256": cfg["source_sha256"],
                "validation": validation,
            },
            indent=2,
        )
        + "\n",
        encoding="utf-8",
    )

    spec = f"""Design Name: {design}_streaming
Module Name: {cfg['top']}

Inputs:
- clk
- rst                         // Active-high synchronous reset
- valid_in
- data_in[31:0]               // IEEE-754 binary32 word

Outputs:
- valid_out
- data_out[31:0]              // IEEE-754 binary32 word

Parameters:
- TAP_CNT = 101

Required behavior:
- Accept one sample whenever valid_in is asserted.
- Produce exactly one ordered output per accepted input after a fixed implementation latency.
- Use zero-valued history before the first input sample.
- Compute the causal 101-tap FIR whose exact binary32 coefficients are listed below.
- Implement binary32 multiplication and addition; sequential MAC and equivalent pipelined trees are permitted.
- Outputs must be finite and are compared with absolute tolerance 1e-6 and exact cardinality.

Recovered filter provenance:
- {cfg['generator']}.
- Official commit c087e0418cb227e721b597f600bd608d3bf6babc retains a full-precision upstream oracle.
- It agrees with the stated float64 FIR model to <= {cfg['upstream_float64_max_error']:.17g} over all 1000 samples.
- The released binary32 vectors agree with sequential binary32 evaluation to max absolute error {validation['fp32_sequential_max_abs_error']:.9g}; samples 101..999 are an 899-sample holdout.

Exact coefficient words:
{_coefficient_spec(cfg['coefficient_words'])}

Design signature:

module {cfg['top']} #(
    parameter TAP_CNT = 101
) (
    input wire clk,
    input wire rst,
    input wire valid_in,
    input wire [31:0] data_in,
    output wire valid_out,
    output wire [31:0] data_out
);
"""
    (destination / "design-specs.txt").write_text(spec, encoding="utf-8")

    provenance = f"""# Recovered {design} contract

This copied fixture does not modify the original benchmark or the live main
repaired-contract root.

The published 31-tap coefficient list is not the golden oracle. Direct causal
convolution with that list has maximum error greater than 0.29. The official
upstream history at commit `c087e0418cb227e721b597f600bd608d3bf6babc`
retains a full-precision output file named `{cfg['upstream_output']}`. The model
`{cfg['generator']}` reproduces that 1,000-sample oracle to maximum absolute
error `{cfg['upstream_float64_max_error']:.17g}`. The first 101 transient
samples establish the impulse response and samples 101--999 form an 899-sample
holdout.

The shipped +/-1.0 comparator is rejected: the largest released output
magnitude is only `{validation['maximum_golden_magnitude']:.9g}`, so an all-zero
DUT passes it. This fixture requires finite FP32 values, exact output length,
and absolute tolerance `1e-6`.

Upstream directory:
https://github.com/sureshpurini/ArchXBench/tree/c087e0418cb227e721b597f600bd608d3bf6babc/level-6/{design}
"""
    (destination / "RECOVERED_CONTRACT.md").write_text(provenance, encoding="utf-8")
    return validation


def main() -> None:
    # Low-pass recovery owns its own source-integrity and semantic checks.
    low.main()
    validations = {"fp_low_pass_fir": json.loads(
        (RECOVERED_ROOT / "level-6" / "fp_low_pass_fir" / "recovered_fir_contract.json").read_text()
    )["validation"]}
    for design, cfg in DESIGNS.items():
        validations[design] = _stage(design, cfg)

    manifest = {
        "source_root": str(SOURCE_LEVEL.parent.relative_to(REPO_ROOT)),
        "recovered_root": str(RECOVERED_ROOT.relative_to(REPO_ROOT)),
        "status": "recovered_and_independently_validated",
        "comparison": {
            "mode": "fp32",
            "absolute_tolerance": 1e-6,
            "require_exact_length": True,
            "require_finite": True,
        },
        "designs": [
            {
                "level": "level-6",
                "design": design,
                "tap_count": 101,
                "validation": validation,
            }
            for design, validation in validations.items()
        ],
    }
    (RECOVERED_ROOT / "manifest.json").write_text(
        json.dumps(manifest, indent=2) + "\n",
        encoding="utf-8",
    )
    print(f"Wrote all recovered FP FIR fixtures to {RECOVERED_ROOT}")
    print(json.dumps(validations, indent=2))


if __name__ == "__main__":
    main()
