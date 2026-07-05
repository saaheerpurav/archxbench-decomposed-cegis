`timescale 1ns/1ps

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
