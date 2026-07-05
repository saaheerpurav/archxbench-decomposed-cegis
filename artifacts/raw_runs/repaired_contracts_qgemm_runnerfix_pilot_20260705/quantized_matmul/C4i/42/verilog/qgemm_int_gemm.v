`timescale 1ns/1ps

module qgemm_int_gemm #(
  parameter VLEN = 8,
  parameter K = 64,
  parameter QBW = 8,
  parameter ACC_W = 32
)(
  input signed [VLEN*K*QBW-1:0] A_q,
  input signed [K*VLEN*QBW-1:0] B_q,
  input [QBW-1:0] zp_A,
  input [QBW-1:0] zp_B,
  output reg signed [VLEN*VLEN*ACC_W-1:0] C_acc
);

  localparam CENTER_W = QBW + 1;
  localparam PROD_W = 2 * CENTER_W;

  integer i;
  integer j;
  integer k;

  reg signed [QBW-1:0] a_val;
  reg signed [QBW-1:0] b_val;
  reg signed [QBW-1:0] zpa_s;
  reg signed [QBW-1:0] zpb_s;

  reg signed [CENTER_W-1:0] a_centered;
  reg signed [CENTER_W-1:0] b_centered;
  reg signed [PROD_W-1:0] product;
  reg signed [ACC_W-1:0] acc;

  always @* begin
    C_acc = {VLEN*VLEN*ACC_W{1'b0}};

    zpa_s = zp_A;
    zpb_s = zp_B;

    for (i = 0; i < VLEN; i = i + 1) begin
      for (j = 0; j < VLEN; j = j + 1) begin
        acc = {ACC_W{1'b0}};

        for (k = 0; k < K; k = k + 1) begin
          a_val = A_q[(i*K + k)*QBW +: QBW];
          b_val = B_q[(k*VLEN + j)*QBW +: QBW];

          a_centered = {a_val[QBW-1], a_val} - {zpa_s[QBW-1], zpa_s};
          b_centered = {b_val[QBW-1], b_val} - {zpb_s[QBW-1], zpb_s};

          product = a_centered * b_centered;
          acc = acc + {{(ACC_W-PROD_W){product[PROD_W-1]}}, product};
        end

        C_acc[(i*VLEN + j)*ACC_W +: ACC_W] = acc;
      end
    end
  end

endmodule