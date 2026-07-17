"""Prepare the independently recovered L6 floating-point low-pass FIR contract.

The released row is not executable as shipped: its testbench references files
that do not exist, writes a filename the comparator does not read, gives a
31-tap default for a 101-tap golden, and omits the coefficients.  This script
copies the release into a separate, explicitly recovered benchmark root.  It
never modifies the original benchmark or the main repaired-contract root.
"""

from __future__ import annotations

import hashlib
import json
import shutil
import struct
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[1]
SOURCE = (
    REPO_ROOT
    / "cegis"
    / "tdes"
    / "fpga"
    / "benchmarks"
    / "archxbench"
    / "level-6"
    / "fp_low_pass_fir"
)
RECOVERED_ROOT = (
    REPO_ROOT
    / "artifacts"
    / "benchmark_contracts"
    / "archxbench_recovered_fp_low"
)
DESTINATION = RECOVERED_ROOT / "level-6" / "fp_low_pass_fir"

EXPECTED_SHA256 = {
    "inputs/stimuli.json": "ff35aed952d0a7ec3d07e622b655f6d64f8b659856c772211b114f94294462c9",
    "outputs/golden_output.json": "daef79353682bbfaaf3714f678723b3187b0e59d3e2077a6652340456569a671",
}

# scipy.signal.firwin(101, 1000, fs=50000), rounded to public FP32 words.
# Recovery provenance and independent holdout evidence are recorded below.
COEFFICIENT_WORDS = [
    "a012b177", "b8899b4e", "b9100cde", "b9658a36", "b9a46f97",
    "b9de9774", "ba1138b0", "ba385a59", "ba64beaf", "ba8b0c70",
    "baa5db4a", "bac23c16", "badf6632", "bafc57d6", "bb0bebe1",
    "bb183c76", "bb225021", "bb29462d", "bb2c2f7f", "bb2a1427",
    "bb21f9a9", "bb12e9c7", "baf7f357", "bab8a276", "ba4cc970",
    "21778b78", "3a76ed36", "3b064780", "3b59ba00", "3b9bf8d7",
    "3bd04a05", "3c04c2ee", "3c23a218", "3c447ffc", "3c670c62",
    "3c857531", "3c97d8e8", "3caa7876", "3cbd1733", "3ccf75c9",
    "3ce1536a", "3cf26f15", "3d014471", "3d08b1ac", "3d0f6255",
    "3d153bfc", "3d1a2735", "3d1e101a", "3d20e6b9", "3d229f6d",
    "3d23331f", "3d229f6d", "3d20e6b9", "3d1e101a", "3d1a2735",
    "3d153bfc", "3d0f6255", "3d08b1ac", "3d014471", "3cf26f15",
    "3ce1536a", "3ccf75c9", "3cbd1733", "3caa7876", "3c97d8e8",
    "3c857531", "3c670c62", "3c447ffc", "3c23a218", "3c04c2ee",
    "3bd04a05", "3b9bf8d7", "3b59ba00", "3b064780", "3a76ed36",
    "21778b78", "ba4cc970", "bab8a276", "baf7f357", "bb12e9c7",
    "bb21f9a9", "bb2a1427", "bb2c2f7f", "bb29462d", "bb225021",
    "bb183c76", "bb0bebe1", "bafc57d6", "badf6632", "bac23c16",
    "baa5db4a", "ba8b0c70", "ba64beaf", "ba385a59", "ba1138b0",
    "b9de9774", "b9a46f97", "b9658a36", "b9100cde", "b8899b4e",
    "a012b177",
]


TESTBENCH = r"""`timescale 1ns/1ps

module tb_lowpass_fir_fp;
  parameter TAP_CNT = 101;
  localparam MAX_SAMPLES = 65536;
  localparam MAX_DRAIN_CYCLES = MAX_SAMPLES + 8192;
  localparam EXTRA_GUARD_CYCLES = TAP_CNT * 4 + 128;

  reg clk = 0;
  reg rst;
  reg valid_in;
  reg [31:0] data_in;
  wire valid_out;
  wire [31:0] data_out;

  integer infile, outfile, code;
  integer idx, sample_count, out_count, drain_cycles, guard_cycles;
  reg [31:0] samples [0:MAX_SAMPLES-1];

  fp_lowpass_fir #(.TAP_CNT(TAP_CNT)) dut (
    .clk(clk),
    .rst(rst),
    .valid_in(valid_in),
    .data_in(data_in),
    .valid_out(valid_out),
    .data_out(data_out)
  );

  always #5 clk = ~clk;

  task capture_output;
    begin
      if (valid_out) begin
        if (out_count > 0)
          $fwrite(outfile, ",\n");
        $fwrite(outfile, "  \"%08h\"", data_out);
        out_count = out_count + 1;
      end
    end
  endtask

  initial begin
    rst = 1;
    valid_in = 0;
    data_in = 32'h00000000;
    out_count = 0;

    infile = $fopen("inputs/stimuli.json", "r");
    if (infile == 0) begin
      $display("[FAIL] Cannot open inputs/stimuli.json");
      $finish;
    end
    sample_count = 0;
    while (!$feof(infile) && sample_count < MAX_SAMPLES) begin
      code = $fscanf(infile, "%h", samples[sample_count]);
      if (code == 1)
        sample_count = sample_count + 1;
      else
        code = $fgetc(infile);
    end
    $fclose(infile);
    if (sample_count == 0 || sample_count == MAX_SAMPLES) begin
      $display("[FAIL] Invalid input sample count: %0d", sample_count);
      $finish;
    end

    outfile = $fopen("outputs/dut_output.json", "w");
    if (outfile == 0) begin
      $display("[FAIL] Cannot open outputs/dut_output.json");
      $finish;
    end
    $fwrite(outfile, "[\n");

    repeat (3) @(negedge clk);
    rst = 0;

    for (idx = 0; idx < sample_count; idx = idx + 1) begin
      @(negedge clk);
      valid_in = 1;
      data_in = samples[idx];
      @(posedge clk);
      #1 capture_output;
    end

    @(negedge clk);
    valid_in = 0;
    data_in = 32'h00000000;

    drain_cycles = 0;
    while (out_count < sample_count && drain_cycles < MAX_DRAIN_CYCLES) begin
      @(posedge clk);
      #1 capture_output;
      drain_cycles = drain_cycles + 1;
    end

    // Continue briefly after the expected cardinality.  Any spurious valid_out
    // pulses are written and rejected by the exact-length golden comparator.
    for (guard_cycles = 0; guard_cycles < EXTRA_GUARD_CYCLES; guard_cycles = guard_cycles + 1) begin
      @(posedge clk);
      #1 capture_output;
    end

    $fwrite(outfile, "\n]\n");
    $fclose(outfile);
    if (out_count == sample_count)
      $display("[PASS] Wrote exactly %0d ordered outputs", out_count);
    else
      $display("[FAIL] Wrote %0d outputs; expected %0d", out_count, sample_count);
    $finish;
  end
endmodule
"""


COMPARE_SCRIPT = r'''#!/usr/bin/env python3
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
'''


def _sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def _fp32(word: str) -> float:
    return struct.unpack("!f", struct.pack("!I", int(word, 16)))[0]


def _round_fp32(value: float) -> float:
    return struct.unpack("!f", struct.pack("!f", value))[0]


def _verify_source_and_recovered_model() -> dict[str, float | int]:
    for relative, expected in EXPECTED_SHA256.items():
        actual = _sha256(SOURCE / relative)
        if actual != expected:
            raise RuntimeError(
                f"Refusing to recover changed source asset {relative}: "
                f"expected {expected}, got {actual}"
            )

    stimuli_raw = json.loads((SOURCE / "inputs" / "stimuli.json").read_text())
    golden_raw = json.loads((SOURCE / "outputs" / "golden_output.json").read_text())
    if len(stimuli_raw) != 1000 or len(golden_raw) != 1000:
        raise RuntimeError("Expected exactly 1000 released stimuli and golden samples")
    if len(COEFFICIENT_WORDS) != 101:
        raise RuntimeError("Recovered coefficient list must contain exactly 101 taps")

    stimuli = [_fp32(item.removeprefix("0x")) for item in stimuli_raw]
    golden = [_fp32(item.removeprefix("0x")) for item in golden_raw]
    coefficients = [_fp32(item) for item in COEFFICIENT_WORDS]

    predicted: list[float] = []
    for sample_index in range(len(stimuli)):
        accumulator = _round_fp32(0.0)
        for tap_index, coefficient in enumerate(coefficients):
            if sample_index < tap_index:
                break
            product = _round_fp32(stimuli[sample_index - tap_index] * coefficient)
            accumulator = _round_fp32(accumulator + product)
        predicted.append(accumulator)

    errors = [abs(reference - candidate) for reference, candidate in zip(golden, predicted)]
    max_error = max(errors)
    holdout_errors = errors[101:]
    if max_error > 1e-6 or max(holdout_errors) > 1e-6:
        raise RuntimeError(
            f"Recovered FP32 model failed validation: max_error={max_error}, "
            f"holdout_max_error={max(holdout_errors)}"
        )
    return {
        "sample_count": len(golden),
        "tap_count": len(coefficients),
        "transient_identification_samples": 101,
        "holdout_samples": len(holdout_errors),
        "fp32_sequential_max_abs_error": max_error,
        "fp32_sequential_holdout_max_abs_error": max(holdout_errors),
    }


def _coefficient_spec() -> str:
    entries = [f"  h[{index:3d}] = 32'h{word};" for index, word in enumerate(COEFFICIENT_WORDS)]
    return "\n".join(entries)


def _write_spec(validation: dict[str, float | int]) -> None:
    spec = f"""Design Name: fp_lowpass_fir_streaming
Module Name: fp_lowpass_fir

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
- Produce exactly one ordered output for every accepted input after a fixed implementation latency.
- Use zero-valued history before the first input sample.
- Compute the causal 101-tap low-pass FIR whose coefficients are the binary32 words below.
- Implement binary32 multiplication and addition. A sequential MAC or an equivalent pipelined tree is permitted.
- The executable contract compares finite binary32 values with absolute tolerance 1e-6 and requires exact output length.

Recovered filter provenance:
- scipy.signal.firwin(101, 1000, fs=50000), default Hamming window and scale=True.
- The earlier official ArchXBench commit c087e0418cb227e721b597f600bd608d3bf6babc publishes full-precision input_signal.json and golden_output_fp.json.
- That independent upstream oracle agrees with the stated float64 FIR model to <= 2.220446049250313e-16 over all 1000 samples.
- The released binary32 vectors agree with a sequential binary32 implementation to max absolute error {validation['fp32_sequential_max_abs_error']:.9g}; samples 101..999 are an 899-sample holdout.

Exact coefficient words:
{_coefficient_spec()}

Design signature:

module fp_lowpass_fir #(
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
    (DESTINATION / "design-specs.txt").write_text(spec, encoding="utf-8")


def main() -> None:
    validation = _verify_source_and_recovered_model()

    if DESTINATION.exists():
        shutil.rmtree(DESTINATION)
    DESTINATION.parent.mkdir(parents=True, exist_ok=True)
    shutil.copytree(SOURCE, DESTINATION)

    (DESTINATION / "tb_fp_lowpass_fir.v").write_text(TESTBENCH, encoding="utf-8")
    (DESTINATION / "scripts" / "compare_outputs.py").write_text(
        COMPARE_SCRIPT,
        encoding="utf-8",
    )
    (DESTINATION / "golden_contract.json").write_text(
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
    (DESTINATION / "recovered_fir_contract.json").write_text(
        json.dumps(
            {
                "tap_count": 101,
                "sample_rate_hz": 50000,
                "cutoff_hz": 1000,
                "coefficient_generator": "scipy.signal.firwin(101, 1000, fs=50000)",
                "coefficient_words_fp32": [f"0x{word}" for word in COEFFICIENT_WORDS],
                "source_asset_sha256": EXPECTED_SHA256,
                "validation": validation,
            },
            indent=2,
        )
        + "\n",
        encoding="utf-8",
    )
    _write_spec(validation)

    provenance = """# Recovered FP low-pass FIR contract

This is a separate copied fixture. The original ArchXBench source and the main
`archxbench_repaired` root are unchanged.

Why recovery is justified:

- The released testbench says 31 taps but the golden transient is generated by 101 taps.
- The earlier official upstream commit `c087e0418cb227e721b597f600bd608d3bf6babc`
  retains full-precision `input_signal.json` and `golden_output_fp.json`.
- `scipy.signal.firwin(101, 1000, fs=50000)` followed by causal FIR filtering
  reproduces all 1,000 full-precision outputs within `2.220446049250313e-16`.
- The first 101 transient samples establish the impulse response; samples
  101--999 are an independent 899-sample holdout.
- The Level-4 low-pass release uses the same 101-tap/1-kHz filter family and
  the same signal and plots, providing cross-row corroboration.

Upstream evidence:

- https://github.com/sureshpurini/ArchXBench/tree/c087e0418cb227e721b597f600bd608d3bf6babc/level-6/fp_low_pass_fir
- https://raw.githubusercontent.com/sureshpurini/ArchXBench/c087e0418cb227e721b597f600bd608d3bf6babc/level-6/fp_low_pass_fir/inputs/input_signal.json
- https://raw.githubusercontent.com/sureshpurini/ArchXBench/c087e0418cb227e721b597f600bd608d3bf6babc/level-6/fp_low_pass_fir/outputs/golden_output_fp.json

The shipped `+/-1.0` floating-point comparator is not retained: every released
golden magnitude is below 1.0, so an all-zero DUT passes it. This recovered
fixture uses absolute tolerance `1e-6`, rejects non-finite values, and requires
exact output cardinality. Valid sequential and balanced-tree binary32 FIR
evaluation differ from the released golden by less than `3e-7`.
"""
    (DESTINATION / "RECOVERED_CONTRACT.md").write_text(provenance, encoding="utf-8")

    manifest = {
        "source_root": str(SOURCE.relative_to(REPO_ROOT)),
        "recovered_root": str(RECOVERED_ROOT.relative_to(REPO_ROOT)),
        "designs": [
            {
                "level": "level-6",
                "design": "fp_low_pass_fir",
                "status": "recovered_and_independently_validated",
                "repairs": [
                    "correct top-module name to fp_lowpass_fir",
                    "correct TAP_CNT from 31 to 101",
                    "publish recovered 101 binary32 coefficient words",
                    "read released inputs/stimuli.json",
                    "write outputs/dut_output.json",
                    "capture and drain exactly one output per input",
                    "enforce finite FP32 absolute tolerance 1e-6",
                    "enforce exact output cardinality",
                ],
            }
        ],
    }
    RECOVERED_ROOT.mkdir(parents=True, exist_ok=True)
    (RECOVERED_ROOT / "manifest.json").write_text(
        json.dumps(manifest, indent=2) + "\n",
        encoding="utf-8",
    )
    print(f"Wrote recovered FP low-pass fixture to {DESTINATION}")
    print(json.dumps(validation, indent=2))


if __name__ == "__main__":
    main()
