`timescale 1ns/1ps

module qgemm_int_matmul #(
  parameter VLEN = 8,
  parameter K = 64,
  parameter QBW = 8,
  parameter ACC_W = 32
)(
  input  wire [VLEN*K*QBW-1:0] A_q,
  input  wire [K*VLEN*QBW-1:0] B_q,
  input  wire [QBW-1:0] zp_A,
  input  wire [QBW-1:0] zp_B,
  output reg  [VLEN*VLEN*ACC_W-1:0] C_acc
);

  integer i;
  integer j;
  integer kk;
  integer a_idx;
  integer b_idx;
  integer c_idx;

  reg signed [QBW:0] aval;
  reg signed [QBW:0] bval;
  reg signed [ACC_W-1:0] sum;

  always @* begin
    C_acc = {VLEN*VLEN*ACC_W{1'b0}};

    for (i = 0; i < VLEN; i = i + 1) begin
      for (j = 0; j < VLEN; j = j + 1) begin
        sum = {ACC_W{1'b0}};

        for (kk = 0; kk < K; kk = kk + 1) begin
          a_idx = i*K + kk;
          b_idx = kk*VLEN + j;

          aval = $signed({1'b0, A_q[(VLEN*K - 1 - a_idx)*QBW +: QBW]}) -
                 $signed({1'b0, zp_A});

          bval = $signed({1'b0, B_q[(K*VLEN - 1 - b_idx)*QBW +: QBW]}) -
                 $signed({1'b0, zp_B});

          sum = sum + (aval * bval);
        end

        c_idx = (VLEN * VLEN - 1) - (i * VLEN + j);
        C_acc[c_idx*ACC_W +: ACC_W] = sum;
      end
    end
  end

endmodule