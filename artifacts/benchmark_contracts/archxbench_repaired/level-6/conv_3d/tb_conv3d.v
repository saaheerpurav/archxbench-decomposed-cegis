`timescale 1ns/1ps

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
