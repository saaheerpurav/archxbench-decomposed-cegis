`timescale 1ns/1ps

module qgemm_int_gemm #(
  parameter VLEN  = 8,
  parameter K     = 64,
  parameter ACC_W = 32
)(
  input  [VLEN*K*ACC_W-1:0]    A_q_centered,
  input  [K*VLEN*ACC_W-1:0]    B_q_centered,
  output reg [VLEN*VLEN*ACC_W-1:0] C_acc
);

  localparam signed [63:0] INT32_MAX = 64'sd2147483647;
  localparam signed [63:0] INT32_MIN = -64'sd2147483648;

  integer i;
  integer j;
  integer kidx;

  reg signed [ACC_W-1:0] a_val;
  reg signed [ACC_W-1:0] b_val;
  reg signed [63:0] a_ext;
  reg signed [63:0] b_ext;
  reg signed [63:0] sum;

  always @* begin
    C_acc = {(VLEN*VLEN*ACC_W){1'b0}};

    for (i = 0; i < VLEN; i = i + 1) begin
      for (j = 0; j < VLEN; j = j + 1) begin
        sum = 64'sd0;

        for (kidx = 0; kidx < K; kidx = kidx + 1) begin
          a_val = A_q_centered[(i*K + kidx)*ACC_W +: ACC_W];
          b_val = B_q_centered[(kidx*VLEN + j)*ACC_W +: ACC_W];

          a_ext = {{(64-ACC_W){a_val[ACC_W-1]}}, a_val};
          b_ext = {{(64-ACC_W){b_val[ACC_W-1]}}, b_val};

          sum = sum + (a_ext * b_ext);
        end

        if (sum > INT32_MAX) begin
          C_acc[(i*VLEN + j)*ACC_W +: ACC_W] = 32'h7fffffff;
        end else if (sum < INT32_MIN) begin
          C_acc[(i*VLEN + j)*ACC_W +: ACC_W] = 32'h80000000;
        end else begin
          C_acc[(i*VLEN + j)*ACC_W +: ACC_W] = sum[ACC_W-1:0];
        end
      end
    end
  end

endmodule