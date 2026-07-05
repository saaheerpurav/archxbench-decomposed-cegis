"""Prepare repaired ArchXBench contract fixtures.

This script does not modify the original benchmark copy under
`cegis/tdes/fpga/benchmarks/archxbench`. It creates a small alternate
ArchXBench root under `artifacts/benchmark_contracts/archxbench_repaired`
containing only benchmarks whose testbench/data contract is being repaired.

Use the repaired root with:

    $env:ARCHXBENCH_ROOT = "<repo>/artifacts/benchmark_contracts/archxbench_repaired"

The goal is to make benchmark-contract changes explicit and reproducible.
"""

from __future__ import annotations

import json
import shutil
import struct
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[1]
SOURCE_ROOT = REPO_ROOT / "cegis" / "tdes" / "fpga" / "benchmarks" / "archxbench"
REPAIRED_ROOT = REPO_ROOT / "artifacts" / "benchmark_contracts" / "archxbench_repaired"


CONV3D_TB = r"""`timescale 1ns/1ps

module tb_conv3d;

  parameter K1 = 3, K2 = 3, K3 = 3;
  parameter D  = 8, H  = 64, W  = 64;
  parameter DATA_W = 8;

  localparam N = D * H * W;
  localparam OUT_D = D - K1 + 1;
  localparam OUT_H = H - K2 + 1;
  localparam OUT_WID = W - K3 + 1;
  localparam OUT_N = OUT_D * OUT_H * OUT_WID;
  localparam SUM_W = DATA_W + 5;  // max 27 * 255 = 6885, needs 13 bits

  reg clk, rst, valid_in, last_in;
  reg  [DATA_W-1:0] voxel_in;
  reg  [K1*K2*K3*DATA_W-1:0] kernel;
  wire [SUM_W-1:0] voxel_out;
  wire valid_out;
  wire done;

  reg [7:0] input_volume [0:N-1];
  integer i, out_count, fout, cycles;

  conv3d #(
    .K1(K1), .K2(K2), .K3(K3),
    .D(D), .H(H), .W(W),
    .DATA_W(DATA_W)
  ) dut (
    .clk(clk),
    .rst(rst),
    .voxel_in(voxel_in),
    .valid_in(valid_in),
    .kernel(kernel),
    .last_in(last_in),
    .voxel_out(voxel_out),
    .valid_out(valid_out),
    .done(done)
  );

  always #5 clk = ~clk;

  initial begin
    $readmemh("tb_input.mem", input_volume);

    clk = 0;
    rst = 1;
    valid_in = 0;
    last_in = 0;
    voxel_in = 0;
    kernel = {K1*K2*K3{8'h01}};  // Python reference uses a 3x3x3 all-ones kernel.
    out_count = 0;
    cycles = 0;

    fout = $fopen("outputs/dut_output.json", "w");
    $fwrite(fout, "{\n  \"C\": [\n");

    #20 rst = 0;

    for (i = 0; i < N; i = i + 1) begin
      @(negedge clk);
      voxel_in = input_volume[i];
      valid_in = 1;
      last_in = (i == N-1);
      @(posedge clk);
      if (valid_out && out_count < OUT_N) begin
        $fwrite(fout, "    %0d%s\n", voxel_out, (out_count == OUT_N-1) ? "" : ",");
        out_count = out_count + 1;
      end
    end

    @(negedge clk);
    valid_in = 0;
    last_in = 0;
    voxel_in = 0;

    while (out_count < OUT_N && cycles < N) begin
      @(posedge clk);
      if (valid_out) begin
        $fwrite(fout, "    %0d%s\n", voxel_out, (out_count == OUT_N-1) ? "" : ",");
        out_count = out_count + 1;
      end
      cycles = cycles + 1;
    end

    $fwrite(fout, "  ]\n}\n");
    $fclose(fout);

    if (out_count == OUT_N) begin
      $display("[PASS] conv3d wrote %0d outputs", out_count);
    end else begin
      $display("[FAIL] conv3d wrote %0d/%0d outputs", out_count, OUT_N);
    end
    $finish;
  end
endmodule
"""


def _copy_design(level: str, design: str) -> Path:
    src = SOURCE_ROOT / level / design
    dst = REPAIRED_ROOT / level / design
    if dst.exists():
        shutil.rmtree(dst)
    shutil.copytree(src, dst)
    return dst


def _float_to_u32(value: float) -> int:
    return struct.unpack("<I", struct.pack("<f", float(value)))[0]


def _flatten(value):
    if isinstance(value, dict):
        value = list(value.values())
    if isinstance(value, list) and value and isinstance(value[0], list):
        return [item for row in value for item in row]
    return value


def _repair_quantized_matmul() -> None:
    dst = _copy_design("level-6", "quantized_matmul")

    stimuli = json.loads((dst / "inputs" / "stimuli.json").read_text(encoding="utf-8"))
    with (dst / "tb_float.mem").open("w", encoding="utf-8") as fh:
        for row in stimuli["A_fp"]:
            for item in row:
                fh.write(f"{_float_to_u32(item):08x}\n")
        for row in stimuli["B_fp"]:
            for item in row:
                fh.write(f"{_float_to_u32(item):08x}\n")

    with (dst / "tb_params.mem").open("w", encoding="utf-8") as fh:
        fh.write(f"{stimuli['zp_A'] & 0xFF:02x}\n")
        fh.write(f"{stimuli['zp_B'] & 0xFF:02x}\n")
        fh.write(f"{stimuli['scale_A'] & 0xFFFF:04x}\n")
        fh.write(f"{stimuli['scale_B'] & 0xFFFF:04x}\n")

    golden = json.loads((dst / "outputs" / "golden_output.json").read_text(encoding="utf-8"))
    flat_bits = [_float_to_u32(item) for item in _flatten(golden["C"])]
    (dst / "outputs" / "golden_output.json").write_text(
        json.dumps({"C": flat_bits}, indent=2) + "\n",
        encoding="utf-8",
    )

    note = (
        "# Repaired contract notes\n\n"
        "- Original `tb_qgemm.v` read `tb_float.mem`, but the benchmark only shipped `tb_data.mem`.\n"
        "- This fixture regenerates `tb_float.mem` from `inputs/stimuli.json`.\n"
        "- The DUT interface emits packed FP32 bits, so `golden_output.json` is normalized to FP32 bit-pattern integers.\n"
        "- Internal quantization follows the Python reference exactly: signed two's-complement INT8 values, no unsigned clamp to `0..255`.\n"
        "- For the official stimulus, `B_q = round(B_fp / scale_B) + zp_B` includes negative values.\n"
        "- The original source benchmark is unchanged.\n"
    )
    (dst / "REPAIRED_CONTRACT.md").write_text(note, encoding="utf-8")
    _append_contract_note(
        dst / "design-specs.txt",
        [
            "Repaired benchmark contract:",
            "- Testbench input memory file is `tb_float.mem`, generated from `inputs/stimuli.json`.",
            "- `C_fp` is compared as packed IEEE-754 FP32 bit-patterns in output order.",
            "- The golden JSON in this repaired fixture stores those FP32 bit-pattern integers.",
            "- Quantization must match the Python reference: `q = round(fp / scale) + zp`, represented as signed two's-complement INT8.",
            "- Do not clamp quantized values to unsigned `0..255`; the official `B_q` values include negatives.",
            "- Matrix multiply uses the signed centered values `(A_q - zp_A)` and `(B_q - zp_B)`.",
        ],
    )


def _repair_conv_3d() -> None:
    dst = _copy_design("level-6", "conv_3d")
    (dst / "tb_conv3d.v").write_text(CONV3D_TB, encoding="utf-8")
    note = (
        "# Repaired contract notes\n\n"
        "- Original testbench drove `kernel = 0`, while the Python reference uses a 3x3x3 all-ones kernel.\n"
        "- Original testbench wrote one output per input voxel instead of one output per valid convolution window.\n"
        "- Original output width was `DATA_W+4`; this fixture uses `DATA_W+5`, enough for 27 unsigned 8-bit terms.\n"
        "- The fixture writes exactly `(D-K1+1)*(H-K2+1)*(W-K3+1)` outputs and checks that count.\n"
        "- The original source benchmark is unchanged.\n"
    )
    (dst / "REPAIRED_CONTRACT.md").write_text(note, encoding="utf-8")
    _append_contract_note(
        dst / "design-specs.txt",
        [
            "Repaired benchmark contract:",
            "- The testbench drives a 3x3x3 all-ones kernel, matching the Python reference model.",
            "- `valid_out` must assert only for valid convolution windows.",
            "- The DUT must emit exactly `(D-K1+1)*(H-K2+1)*(W-K3+1)` outputs.",
            "- Output width must represent the sum of 27 unsigned 8-bit products with unit coefficients.",
        ],
    )


def _append_contract_note(path: Path, lines: list[str]) -> None:
    text = path.read_text(encoding="utf-8", errors="ignore").rstrip()
    addition = "\n\n" + "\n".join(lines) + "\n"
    path.write_text(text + addition, encoding="utf-8")


def main() -> None:
    REPAIRED_ROOT.mkdir(parents=True, exist_ok=True)
    _repair_quantized_matmul()
    _repair_conv_3d()
    manifest = {
        "source_root": str(SOURCE_ROOT.relative_to(REPO_ROOT)),
        "repaired_root": str(REPAIRED_ROOT.relative_to(REPO_ROOT)),
        "designs": [
            {
                "level": "level-6",
                "design": "quantized_matmul",
                "repairs": [
                    "generate missing tb_float.mem",
                    "regenerate tb_params.mem from stimuli",
                    "normalize golden_output.json to FP32 bit-pattern integers",
                    "document signed no-saturation quantization semantics",
                ],
            },
            {
                "level": "level-6",
                "design": "conv_3d",
                "repairs": [
                    "drive all-ones kernel to match Python reference",
                    "write only valid convolution outputs",
                    "use sufficient output width",
                ],
            },
        ],
    }
    (REPAIRED_ROOT / "manifest.json").write_text(
        json.dumps(manifest, indent=2) + "\n",
        encoding="utf-8",
    )
    print(f"Wrote repaired contracts to {REPAIRED_ROOT}")


if __name__ == "__main__":
    main()
