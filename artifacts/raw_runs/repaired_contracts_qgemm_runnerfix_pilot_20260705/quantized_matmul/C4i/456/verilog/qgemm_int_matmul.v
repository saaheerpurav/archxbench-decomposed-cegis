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

  integer i, j, kidx;

  reg signed [QBW-1:0] a_val;
  reg signed [QBW-1:0] b_val;
  reg signed [QBW-1:0] zp_a_s;
  reg signed [QBW-1:0] zp_b_s;

  reg signed [QBW:0] a_centered;
  reg signed [QBW:0] b_centered;
  reg signed [(2*QBW)+1:0] product;
  reg signed [ACC_W-1:0] acc;

  always @* begin
    C_acc = {VLEN*VLEN*ACC_W{1'b0}};

    zp_a_s = zp_A;
    zp_b_s = zp_B;

    for (i = 0; i < VLEN; i = i + 1) begin
      for (j = 0; j < VLEN; j = j + 1) begin
        acc = {ACC_W{1'b0}};

        for (kidx = 0; kidx < K; kidx = kidx + 1) begin
          a_val = A_q[(i*K + kidx)*QBW +: QBW];
          b_val = B_q[(kidx*VLEN + j)*QBW +: QBW];

          a_centered = {a_val[QBW-1], a_val} - {zp_a_s[QBW-1], zp_a_s};
          b_centered = {b_val[QBW-1], b_val} - {zp_b_s[QBW-1], zp_b_s};

          product = a_centered * b_centered;
          acc = acc + product;
        end

        C_acc[(i*VLEN + j)*ACC_W +: ACC_W] = acc;
      end
    end
  end

endmodule