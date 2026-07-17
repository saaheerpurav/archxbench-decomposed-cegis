`timescale 1ns/1ps

module tb_fp_band_pass_fir;
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

  fp_bandpass_fir #(.TAP_CNT(TAP_CNT)) dut (
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
