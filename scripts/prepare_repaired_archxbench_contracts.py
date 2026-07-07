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
import re
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


MULTICH_CONV2D_TB = r"""`timescale 1ns/1ps

module tb_multich_conv2d;

  parameter CIN = 3, COUT = 8, K = 3, H = 64, W = 64;
  parameter DATA_W = 8, BIAS_W = 16, OUT_W = 16;

  localparam N = CIN * H * W;
  localparam OUT_H = H - K + 1;
  localparam OUT_WID = W - K + 1;
  localparam OUT_N = COUT * OUT_H * OUT_WID;

  reg clk, rst, valid_in, last_in;
  reg [DATA_W-1:0] pixel_in;
  reg [COUT*CIN*K*K*DATA_W-1:0] kernel;
  reg [COUT*BIAS_W-1:0] bias;
  wire [OUT_W-1:0] pixel_out;
  wire valid_out, done;

  reg [7:0] input_image [0:N-1];
  integer i, out_count, fout, cycles;

  multich_conv2d #(
    .CIN(CIN), .COUT(COUT), .K(K), .H(H), .W(W),
    .DATA_W(DATA_W), .BIAS_W(BIAS_W), .OUT_W(OUT_W)
  ) dut (
    .clk(clk),
    .rst(rst),
    .pixel_in(pixel_in),
    .valid_in(valid_in),
    .last_in(last_in),
    .kernel(kernel),
    .bias(bias),
    .pixel_out(pixel_out),
    .valid_out(valid_out),
    .done(done)
  );

  always #5 clk = ~clk;

  initial begin
    $readmemh("tb_input.mem", input_image);

    clk = 0;
    rst = 1;
    valid_in = 0;
    last_in = 0;
    pixel_in = 0;
    kernel = {COUT*CIN*K*K{8'h01}};  // Python reference uses all-ones kernels.
    bias = {COUT{16'h0000}};
    out_count = 0;
    cycles = 0;

    fout = $fopen("outputs/dut_output.json", "w");
    $fwrite(fout, "{\n  \"C\": [\n");

    #20 rst = 0;

    for (i = 0; i < N; i = i + 1) begin
      @(negedge clk);
      pixel_in = input_image[i];
      valid_in = 1;
      last_in = (i == N-1);
      @(posedge clk);
      if (valid_out && out_count < OUT_N) begin
        $fwrite(fout, "    %0d%s\n", pixel_out, (out_count == OUT_N-1) ? "" : ",");
        out_count = out_count + 1;
      end
    end

    @(negedge clk);
    valid_in = 0;
    last_in = 0;
    pixel_in = 0;

    while (out_count < OUT_N && cycles < N * COUT) begin
      @(posedge clk);
      if (valid_out) begin
        $fwrite(fout, "    %0d%s\n", pixel_out, (out_count == OUT_N-1) ? "" : ",");
        out_count = out_count + 1;
      end
      cycles = cycles + 1;
    end

    $fwrite(fout, "  ]\n}\n");
    $fclose(fout);

    if (out_count == OUT_N) begin
      $display("[PASS] multich_conv2d wrote %0d outputs", out_count);
    end else begin
      $display("[FAIL] multich_conv2d wrote %0d/%0d outputs", out_count, OUT_N);
    end
    $finish;
  end
endmodule
"""


SYSTOLIC_GEMM_TB = r"""`timescale 1ns/1ps

module testbench;
  reg clk = 0;
  reg rst = 0;
  reg [31:0] a_west0, a_west1, a_west2, a_west3;
  reg [31:0] b_north0, b_north1, b_north2, b_north3;
  wire done;
  wire [63:0] result0, result1, result2, result3;
  wire [63:0] result4, result5, result6, result7;
  wire [63:0] result8, result9, result10, result11;
  wire [63:0] result12, result13, result14, result15;

  integer pass_count = 0;
  integer fail_count = 0;
  integer cycle;

  systolic_matrix_mult uut(
    .a_west0(a_west0), .a_west1(a_west1), .a_west2(a_west2), .a_west3(a_west3),
    .b_north0(b_north0), .b_north1(b_north1), .b_north2(b_north2), .b_north3(b_north3),
    .clk(clk), .rst(rst), .done(done),
    .result0(result0), .result1(result1), .result2(result2), .result3(result3),
    .result4(result4), .result5(result5), .result6(result6), .result7(result7),
    .result8(result8), .result9(result9), .result10(result10), .result11(result11),
    .result12(result12), .result13(result13), .result14(result14), .result15(result15)
  );

  always #5 clk = ~clk;

  task clear_inputs;
    begin
      a_west0 = 0; a_west1 = 0; a_west2 = 0; a_west3 = 0;
      b_north0 = 0; b_north1 = 0; b_north2 = 0; b_north3 = 0;
    end
  endtask

  task check64;
    input [127:0] label;
    input [63:0] got;
    input [63:0] exp;
    begin
      if (got === exp) begin
        $display("[PASS] %0s expected=%0d got=%0d", label, exp, got);
        pass_count = pass_count + 1;
      end else begin
        $display("[FAIL] %0s expected=%0d got=%0d", label, exp, got);
        fail_count = fail_count + 1;
      end
    end
  endtask

  task feed_first_case;
    begin
      for (cycle = 0; cycle < 7; cycle = cycle + 1) begin
        @(negedge clk);
        a_west0 = (cycle == 0) ? 32'd1  : (cycle == 1) ? 32'd2  : (cycle == 2) ? 32'd3  : (cycle == 3) ? 32'd4  : 32'd0;
        a_west1 = (cycle == 1) ? 32'd5  : (cycle == 2) ? 32'd6  : (cycle == 3) ? 32'd7  : (cycle == 4) ? 32'd8  : 32'd0;
        a_west2 = (cycle == 2) ? 32'd9  : (cycle == 3) ? 32'd10 : (cycle == 4) ? 32'd11 : (cycle == 5) ? 32'd12 : 32'd0;
        a_west3 = (cycle == 3) ? 32'd13 : (cycle == 4) ? 32'd14 : (cycle == 5) ? 32'd15 : (cycle == 6) ? 32'd16 : 32'd0;
        b_north0 = (cycle == 0) ? 32'd1  : (cycle == 1) ? 32'd5  : (cycle == 2) ? 32'd9  : (cycle == 3) ? 32'd13 : 32'd0;
        b_north1 = (cycle == 1) ? 32'd2  : (cycle == 2) ? 32'd6  : (cycle == 3) ? 32'd10 : (cycle == 4) ? 32'd14 : 32'd0;
        b_north2 = (cycle == 2) ? 32'd3  : (cycle == 3) ? 32'd7  : (cycle == 4) ? 32'd11 : (cycle == 5) ? 32'd15 : 32'd0;
        b_north3 = (cycle == 3) ? 32'd4  : (cycle == 4) ? 32'd8  : (cycle == 5) ? 32'd12 : (cycle == 6) ? 32'd16 : 32'd0;
      end
      @(negedge clk);
      clear_inputs();
    end
  endtask

  task feed_second_case;
    begin
      for (cycle = 0; cycle < 7; cycle = cycle + 1) begin
        @(negedge clk);
        a_west0 = (cycle == 0) ? 32'd0  : (cycle == 1) ? 32'd1  : (cycle == 2) ? 32'd2  : (cycle == 3) ? 32'd3  : 32'd0;
        a_west1 = (cycle == 1) ? 32'd4  : (cycle == 2) ? 32'd5  : (cycle == 3) ? 32'd6  : (cycle == 4) ? 32'd7  : 32'd0;
        a_west2 = (cycle == 2) ? 32'd8  : (cycle == 3) ? 32'd9  : (cycle == 4) ? 32'd10 : (cycle == 5) ? 32'd11 : 32'd0;
        a_west3 = (cycle == 3) ? 32'd12 : (cycle == 4) ? 32'd13 : (cycle == 5) ? 32'd14 : (cycle == 6) ? 32'd15 : 32'd0;
        b_north0 = (cycle == 0) ? 32'd1 : 32'd0;
        b_north1 = (cycle == 2) ? 32'd1 : 32'd0;
        b_north2 = (cycle == 4) ? 32'd1 : 32'd0;
        b_north3 = (cycle == 6) ? 32'd1 : 32'd0;
      end
      @(negedge clk);
      clear_inputs();
    end
  endtask

  task reset_dut;
    begin
      clear_inputs();
      @(negedge clk);
      rst = 1;
      @(negedge clk);
      rst = 0;
    end
  endtask

  initial begin
    reset_dut();
    feed_first_case();
    repeat (12) @(posedge clk);
    check64("A2_r0c0", result0,  64'd90);
    check64("A2_r0c1", result1,  64'd100);
    check64("A2_r0c2", result2,  64'd110);
    check64("A2_r0c3", result3,  64'd120);
    check64("A2_r1c0", result4,  64'd202);
    check64("A2_r1c1", result5,  64'd228);
    check64("A2_r1c2", result6,  64'd254);
    check64("A2_r1c3", result7,  64'd280);
    check64("A2_r2c0", result8,  64'd314);
    check64("A2_r2c1", result9,  64'd356);
    check64("A2_r2c2", result10, 64'd398);
    check64("A2_r2c3", result11, 64'd440);
    check64("A2_r3c0", result12, 64'd426);
    check64("A2_r3c1", result13, 64'd484);
    check64("A2_r3c2", result14, 64'd542);
    check64("A2_r3c3", result15, 64'd600);

    reset_dut();
    feed_second_case();
    repeat (12) @(posedge clk);
    check64("AI_r0c0", result0,  64'd0);
    check64("AI_r0c1", result1,  64'd1);
    check64("AI_r0c2", result2,  64'd2);
    check64("AI_r0c3", result3,  64'd3);
    check64("AI_r1c0", result4,  64'd4);
    check64("AI_r1c1", result5,  64'd5);
    check64("AI_r1c2", result6,  64'd6);
    check64("AI_r1c3", result7,  64'd7);
    check64("AI_r2c0", result8,  64'd8);
    check64("AI_r2c1", result9,  64'd9);
    check64("AI_r2c2", result10, 64'd10);
    check64("AI_r2c3", result11, 64'd11);
    check64("AI_r3c0", result12, 64'd12);
    check64("AI_r3c1", result13, 64'd13);
    check64("AI_r3c2", result14, 64'd14);
    check64("AI_r3c3", result15, 64'd15);

    $display("TEST SUMMARY: %0d PASS, %0d FAILED", pass_count, fail_count);
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


def _repair_multich_conv2d() -> None:
    dst = _copy_design("level-6", "multich_conv2d")
    (dst / "testbench.v").write_text(MULTICH_CONV2D_TB, encoding="utf-8")
    note = (
        "# Repaired contract notes\n\n"
        "- Original testbench drove `kernel = 0`, while the Python reference uses all-ones kernels.\n"
        "- Original testbench opened `dut_output.json` only after all inputs were sent, which can drop streaming outputs.\n"
        "- Original testbench had fragile JSON comma handling and no expected output-count check.\n"
        "- This fixture collects outputs from the start of simulation and writes exactly `COUT*(H-K+1)*(W-K+1)` outputs.\n"
        "- The original source benchmark is unchanged.\n"
    )
    (dst / "REPAIRED_CONTRACT.md").write_text(note, encoding="utf-8")
    _append_contract_note(
        dst / "design-specs.txt",
        [
            "Repaired benchmark contract:",
            "- The testbench drives all-ones kernels, matching the Python reference model.",
            "- Bias is zero for every output channel, matching the Python reference model.",
            "- `valid_out` must assert only for valid output pixels.",
            "- The DUT must emit exactly `COUT*(H-K+1)*(W-K+1)` outputs.",
            "- Output order is flattened as output channel, then row, then column.",
        ],
    )


def _repair_systolic_gemm() -> None:
    dst = _copy_design("level-5", "systolic_gemm")
    (dst / "testbench.v").write_text(SYSTOLIC_GEMM_TB, encoding="utf-8")
    note = (
        "# Repaired contract notes\n\n"
        "- Original testbench printed expected and actual matrices but never emitted machine-readable `[PASS]` or `[FAIL]` checks.\n"
        "- This fixture preserves the two original test cases: `A x A` for values 1..16 and `A x I` for values 0..15.\n"
        "- The fixture turns the expected matrices already printed by the original testbench into 32 explicit output checks.\n"
        "- The fixture removes the testbench-local `include` directive; the runner supplies the generated DUT as `systolic_matrix_mult.v`.\n"
        "- The original source benchmark is unchanged.\n"
    )
    (dst / "REPAIRED_CONTRACT.md").write_text(note, encoding="utf-8")
    _append_contract_note(
        dst / "design-specs.txt",
        [
            "Repaired benchmark contract:",
            "- The checker uses the two deterministic cases printed by the original testbench.",
            "- Case 1 computes the 4x4 matrix product `A x A` for `A = [[1..4], [5..8], [9..12], [13..16]]`.",
            "- Case 2 computes `A x I` for `A = [[0..3], [4..7], [8..11], [12..15]]`.",
            "- Correctness is 32 exact 64-bit result checks, 16 per case.",
        ],
    )


def _repair_l4_fir(design: str, stale_tb: str, module_name: str) -> None:
    dst = _copy_design("level-4", design)
    stale_path = dst / stale_tb
    if stale_path.exists():
        stale_path.unlink()
    note = (
        "# Repaired contract notes\n\n"
        "- The original file-output FIR testbench uses stale interface parameters and JSON output plumbing.\n"
        "- The benchmark directory already contains `tb_selfcheck.v`, an embedded-golden self-checking contract generated from the shipped stimuli and golden outputs.\n"
        "- This repaired fixture removes the stale file-output testbench and makes `tb_selfcheck.v` the only executable contract.\n"
        "- The design spec explicitly lists the required coefficient set and parameters.\n"
        "- The original source benchmark is unchanged.\n"
    )
    (dst / "REPAIRED_CONTRACT.md").write_text(note, encoding="utf-8")
    _append_contract_note(
        dst / "design-specs.txt",
        [
            "Repaired benchmark contract:",
            "- Use `tb_selfcheck.v` as the only executable testbench for this fixture.",
            f"- The top module remains `{module_name}`.",
            "- The stale file-output testbench from the original directory is intentionally removed.",
            "- Correctness is the embedded official 1000-sample golden sequence with +/-1 LSB tolerance.",
        ],
    )


def _strip_hidden_coeff_write(testbench: str) -> str:
    """Remove hierarchical writes like `dut.coeffs[j] = coeffs[j]`.

    Those writes make the benchmark depend on a hidden internal DUT memory name.
    The repaired contract instead requires coefficients to be hard-coded from
    the public spec/testbench coefficient list.
    """
    return re.sub(
        r"\n\s*// Load (?:coefficients|taps) into DUT\s*\n"
        r"\s*for\s*\([^;]+;\s*[^;]+;\s*[^\)]+\)\s*(?:begin\s*)?\n?"
        r"\s*dut\.coeffs\[[^\]]+\]\s*=\s*coeffs\[[^\]]+\];\s*\n"
        r"\s*(?:end\s*)?",
        "\n",
        testbench,
        flags=re.IGNORECASE,
    )


def _repair_valid_out_json_writer(testbench: str) -> str:
    """Make file-output JSON commas depend on actual valid_out count.

    The original FP FIR testbenches decide comma placement from loop indices
    even though output writes are gated by `valid_out`. That can create invalid
    JSON when the number/timing of valid outputs differs from the loop bound.
    """
    text = testbench.replace(
        "integer infile, outfile, code, idx, N;",
        "integer infile, outfile, code, idx, N, out_count;",
    )
    text = text.replace(
        '$fwrite(outfile, "[\\n");\n\n',
        '$fwrite(outfile, "[\\n");\n    out_count = 0;\n\n',
    )
    text = text.replace(
        '        $fwrite(outfile, "  \\"%h\\"", data_out);\n'
        '        if (idx < N-1) $fwrite(outfile, ",\\n");',
        '        if (out_count > 0) $fwrite(outfile, ",\\n");\n'
        '        $fwrite(outfile, "  \\"%h\\"", data_out);\n'
        '        out_count = out_count + 1;',
    )
    text = text.replace(
        '        $fwrite(outfile, "  \\"%h\\"", data_out);\n'
        '        if (idx < TAP_CNT-1) $fwrite(outfile, ",\\n");\n'
        '        else                 $fwrite(outfile, "\\n");',
        '        if (out_count > 0) $fwrite(outfile, ",\\n");\n'
        '        $fwrite(outfile, "  \\"%h\\"", data_out);\n'
        '        out_count = out_count + 1;',
    )
    text = text.replace(
        '$fwrite(outfile, "]\\n");',
        '$fwrite(outfile, "\\n]\\n");',
    )
    return text


def _repair_fp_fir_with_public_coeffs(design: str, tb_name: str, module_name: str) -> None:
    dst = _copy_design("level-6", design)
    tb_path = dst / tb_name
    tb_text = tb_path.read_text(encoding="utf-8", errors="ignore")
    tb_text = _strip_hidden_coeff_write(tb_text)
    tb_text = _repair_valid_out_json_writer(tb_text)
    tb_path.write_text(tb_text, encoding="utf-8")
    note = (
        "# Repaired contract notes\n\n"
        "- The original testbench loaded coefficients through `dut.coeffs[j]`, which assumes a hidden internal DUT memory name not present in the public module interface.\n"
        "- This fixture removes the hierarchical coefficient write. The DUT must hard-code the coefficient set listed in the testbench/spec.\n"
        "- The file-output JSON writer is repaired so commas depend on actual `valid_out` writes instead of loop indices.\n"
        "- The generic runner now compares 32-bit hex JSON outputs as IEEE-754 floats with the benchmark's +/-1.0 tolerance.\n"
        "- The original source benchmark is unchanged.\n"
    )
    (dst / "REPAIRED_CONTRACT.md").write_text(note, encoding="utf-8")
    _append_contract_note(
        dst / "design-specs.txt",
        [
            "Repaired benchmark contract:",
            f"- The top module is `{module_name}`.",
            "- Coefficients must be hard-coded from the public 31-tap coefficient list in the testbench/spec.",
            "- Do not rely on a testbench write to `dut.coeffs`; that hidden internal memory is not part of the module interface.",
            "- The output JSON writer uses an explicit output counter, so only actual `valid_out` writes control comma placement.",
            "- Outputs are 32-bit IEEE-754 hex words compared as floats with +/-1.0 tolerance, matching the shipped comparison script.",
        ],
    )


def _repair_fp_low_pass_fir_hold() -> None:
    dst = _copy_design("level-6", "fp_low_pass_fir")
    note = (
        "# Repaired contract notes\n\n"
        "- This design is copied into the repaired root for audit completeness, but it is intentionally not marked runnable yet.\n"
        "- The original testbench references `inputs/stimuli_fp.json` and `outputs/lowpass_out_fp.json`, while the shipped files are `inputs/stimuli.json` and `outputs/golden_output.json`.\n"
        "- Unlike the band/high-pass FP FIRs, the coefficient list is not present in the testbench.\n"
        "- Do not run or claim this row until the coefficient oracle is recovered from an upstream source or independently validated.\n"
        "- The original source benchmark is unchanged.\n"
    )
    (dst / "REPAIRED_CONTRACT.md").write_text(note, encoding="utf-8")
    _append_contract_note(
        dst / "design-specs.txt",
        [
            "Repaired benchmark contract status:",
            "- Hold unresolved. The shipped file names are inconsistent and the coefficient oracle is not explicit.",
            "- This fixture documents the issue but does not provide a trustworthy repaired executable contract yet.",
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
    _repair_multich_conv2d()
    _repair_systolic_gemm()
    _repair_l4_fir("band_pass_fir", "tb_band_pass_fir.v", "bandpass_fir")
    _repair_l4_fir("high_pass_fir", "tb_high_pass_fir.v", "highpass_fir")
    _repair_l4_fir("low_pass_fir", "tb_low_pass_fir.v", "lowpass_fir")
    _repair_fp_fir_with_public_coeffs("fp_band_pass_fir", "tb_fp_band_pass_fir.v", "fp_bandpass_fir")
    _repair_fp_fir_with_public_coeffs("fp_high_pass_fir", "tb_fp_high_pass_fir.v", "fp_highpass_fir")
    _repair_fp_low_pass_fir_hold()
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
            {
                "level": "level-6",
                "design": "multich_conv2d",
                "repairs": [
                    "drive all-ones kernels to match Python reference",
                    "collect streaming outputs from simulation start",
                    "write exactly the expected output count",
                    "use valid JSON comma handling",
                ],
            },
            {
                "level": "level-5",
                "design": "systolic_gemm",
                "repairs": [
                    "convert displayed expected matrices into machine-readable PASS/FAIL checks",
                    "preserve the original A x A and A x I test cases",
                    "remove duplicate include dependence from the testbench",
                ],
            },
            {
                "level": "level-4",
                "design": "band_pass_fir",
                "repairs": [
                    "remove stale file-output testbench",
                    "use embedded-golden self-checking testbench",
                    "preserve explicit repaired coefficient spec",
                ],
            },
            {
                "level": "level-4",
                "design": "high_pass_fir",
                "repairs": [
                    "remove stale file-output testbench",
                    "use embedded-golden self-checking testbench",
                    "preserve explicit repaired coefficient spec",
                ],
            },
            {
                "level": "level-4",
                "design": "low_pass_fir",
                "repairs": [
                    "remove stale file-output testbench",
                    "use embedded-golden self-checking testbench",
                    "preserve explicit repaired coefficient spec",
                ],
            },
            {
                "level": "level-6",
                "design": "fp_band_pass_fir",
                "repairs": [
                    "remove hidden DUT coefficient-memory writes",
                    "require hard-coded public coefficient list",
                    "compare 32-bit hex outputs as IEEE-754 floats",
                ],
            },
            {
                "level": "level-6",
                "design": "fp_high_pass_fir",
                "repairs": [
                    "remove hidden DUT coefficient-memory writes",
                    "require hard-coded public coefficient list",
                    "compare 32-bit hex outputs as IEEE-754 floats",
                ],
            },
            {
                "level": "level-6",
                "design": "fp_low_pass_fir",
                "repairs": [
                    "document unresolved filename mismatch",
                    "document missing coefficient oracle",
                    "hold out from repaired-contract runs",
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
