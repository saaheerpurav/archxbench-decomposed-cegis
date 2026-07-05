`timescale 1ns/1ps

module qgemm_int_matmul #(
  parameter VLEN = 8,
  parameter K = 64,
  parameter IN_W = 32,
  parameter ACC_W = 32
)(
  input signed [VLEN*K*IN_W-1:0] A_centered,
  input signed [K*VLEN*IN_W-1:0] B_centered,
  output reg signed [VLEN*VLEN*ACC_W-1:0] C_acc
);

  integer i, j, kk;
  reg signed [IN_W-1:0] aval;
  reg signed [IN_W-1:0] bval;
  reg signed [63:0] sum;

  always @* begin
    for (i = 0; i < VLEN; i = i + 1) begin
      for (j = 0; j < VLEN; j = j + 1) begin
        sum = 0;
        for (kk = 0; kk < K; kk = kk + 1) begin
          aval = A_centered[(i*K + kk)*IN_W +: IN_W];
          bval = B_centered[(kk*VLEN + j)*IN_W +: IN_W];
          sum = sum + aval * bval;
        end
        C_acc[(i*VLEN + j)*ACC_W +: ACC_W] = sum[ACC_W-1:0];
      end
    end
  end

endmodule