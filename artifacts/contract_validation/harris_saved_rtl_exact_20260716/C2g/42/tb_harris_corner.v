`timescale 1ns/1ps

module tb_harris_corner;
  parameter PIXEL_W    = 8;
  parameter IMG_WIDTH  = 128;
  parameter IMG_HEIGHT = 128;
  parameter GRAD_W     = 16;
  parameter RESP_W     = 32;
  parameter K_W        = 8;
  localparam N         = IMG_WIDTH * IMG_HEIGHT;
  localparam MAX_DRAIN = N * 2;
  localparam EXTRA_CHECK_CYCLES = 32;

  reg clk = 0;
  reg rst;
  always #5 clk = ~clk;

  reg  [PIXEL_W-1:0] pixel_in;
  reg                valid_in;
  reg  [RESP_W-1:0]  threshold;
  reg  [K_W-1:0]     k_param;
  wire               is_corner;
  wire               valid_out;

  harris_corner #(
    .IMG_WIDTH(IMG_WIDTH), .IMG_HEIGHT(IMG_HEIGHT),
    .PIXEL_W(PIXEL_W), .GRAD_W(GRAD_W),
    .RESP_W(RESP_W), .K_W(K_W)
  ) dut (
    .clk(clk), .rst(rst),
    .pixel_in(pixel_in), .valid_in(valid_in),
    .threshold(threshold), .k_param(k_param),
    .is_corner(is_corner), .valid_out(valid_out)
  );

  integer infile, outfile, code;
  integer loaded_count, drive_idx, out_count, drain_cycles;
  integer ignored_char;
  reg [PIXEL_W-1:0] img [0:N-1];
  reg capture_enabled;

  // Capture independently of the input driver so outputs produced during both
  // the input stream and the pipeline drain are retained.  Commas depend on
  // the actual output count, making the JSON valid for any DUT latency.
  always @(posedge clk) begin
    if (capture_enabled && !rst && valid_out) begin
      if (out_count > 0)
        $fwrite(outfile, ",\n");
      $fwrite(outfile, "  %0d", is_corner);
      out_count = out_count + 1;
    end
  end

  initial begin
    rst = 1;
    valid_in = 0;
    pixel_in = 0;
    threshold = 32'd1000;
    k_param = 8'd5;
    capture_enabled = 0;
    out_count = 0;

    infile = $fopen("inputs/stimuli.json", "r");
    if (infile == 0) begin
      $display("[FAIL] cannot open inputs/stimuli.json");
      $finish;
    end
    loaded_count = 0;
    while (!$feof(infile) && loaded_count < N) begin
      code = $fscanf(infile, "%d", img[loaded_count]);
      if (code == 1)
        loaded_count = loaded_count + 1;
      else
        ignored_char = $fgetc(infile);
    end
    $fclose(infile);
    if (loaded_count != N) begin
      $display("[FAIL] loaded %0d/%0d input pixels", loaded_count, N);
      $finish;
    end

    outfile = $fopen("outputs/dut_output.json", "w");
    if (outfile == 0) begin
      $display("[FAIL] cannot open outputs/dut_output.json");
      $finish;
    end
    $fwrite(outfile, "[\n");

    repeat (2) @(negedge clk);
    rst = 0;
    capture_enabled = 1;

    // Drive on the falling edge so the DUT sees stable inputs at the next
    // rising edge and the output monitor has race-free sampling semantics.
    for (drive_idx = 0; drive_idx < N; drive_idx = drive_idx + 1) begin
      @(negedge clk);
      valid_in = 1;
      pixel_in = img[drive_idx];
    end
    @(negedge clk);
    valid_in = 0;
    pixel_in = 0;

    // A correct implementation may have arbitrary finite pipeline latency.
    // Wait for N outputs, then retain a bounded tail to expose nearby extras.
    drain_cycles = 0;
    while (out_count < N && drain_cycles < MAX_DRAIN) begin
      @(posedge clk);
      drain_cycles = drain_cycles + 1;
    end
    repeat (EXTRA_CHECK_CYCLES) @(posedge clk);
    @(negedge clk);
    capture_enabled = 0;

    $fwrite(outfile, "\n]\n");
    $fclose(outfile);

    if (out_count == N)
      $display("[PASS] harris_corner wrote exactly %0d outputs", out_count);
    else
      $display("[FAIL] harris_corner wrote %0d outputs; expected exactly %0d", out_count, N);
    $finish;
  end
endmodule
