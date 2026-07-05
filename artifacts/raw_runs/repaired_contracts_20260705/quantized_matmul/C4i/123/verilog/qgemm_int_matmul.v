`timescale 1ns/1ps

module qgemm_int_matmul #(
  parameter VLEN = 8,
  parameter K = 64,
  parameter QBW = 8,
  parameter ACC_W = 32
)(
  input  [VLEN*K*QBW-1:0] A_q,
  input  [K*VLEN*QBW-1:0] B_q,
  input  [QBW-1:0] zp_A,
  input  [QBW-1:0] zp_B,
  output reg [VLEN*VLEN*ACC_W-1:0] C_acc
);

  localparam PROD_W = 2 * (QBW + 1);

  integer i;
  integer j;
  integer kidx;

  reg signed [QBW:0] a_centered;
  reg signed [QBW:0] b_centered;
  reg signed [PROD_W-1:0] prod;
  reg signed [ACC_W-1:0] acc;

  always @(*) begin
    C_acc = {VLEN*VLEN*ACC_W{1'b0}};

    for (i = 0; i < VLEN; i = i + 1) begin
      for (j = 0; j < VLEN; j = j + 1) begin
        acc = {ACC_W{1'b0}};

        for (kidx = 0; kidx < K; kidx = kidx + 1) begin
          a_centered = $signed({1'b0, A_q[(i*K + kidx)*QBW +: QBW]}) -
                       $signed({1'b0, zp_A});

          b_centered = $signed({1'b0, B_q[(kidx*VLEN + j)*QBW +: QBW]}) -
                       $signed({1'b0, zp_B});

          prod = a_centered * b_centered;
          acc = acc + {{(ACC_W-PROD_W){prod[PROD_W-1]}}, prod};
        end

        C_acc[(i*VLEN + j)*ACC_W +: ACC_W] = acc;
      end
    end
  end

endmodule