`timescale 1ns/1ps

module qgemm_int_matrix_multiply #(
  parameter VLEN = 8,
  parameter K = 64,
  parameter QBW = 8,
  parameter ACC_W = 32
)(
  input  [VLEN*K*QBW-1:0]        A_q,
  input  [K*VLEN*QBW-1:0]        B_q,
  input  [QBW-1:0]               zp_A,
  input  [QBW-1:0]               zp_B,
  output reg [VLEN*VLEN*ACC_W-1:0] C_acc
);

  localparam CENTER_W = QBW + 1;
  localparam PROD_W   = 2 * CENTER_W;

  integer i;
  integer j;
  integer kk;
  integer a_idx;
  integer b_idx;

  reg signed [QBW-1:0]      a_q_s;
  reg signed [QBW-1:0]      b_q_s;
  reg signed [QBW-1:0]      zp_A_s;
  reg signed [QBW-1:0]      zp_B_s;
  reg signed [CENTER_W-1:0] a_centered;
  reg signed [CENTER_W-1:0] b_centered;
  reg signed [PROD_W-1:0]   product;
  reg signed [ACC_W-1:0]    acc;

  always @* begin
    C_acc = {VLEN*VLEN*ACC_W{1'b0}};

    zp_A_s = zp_A;
    zp_B_s = zp_B;

    for (i = 0; i < VLEN; i = i + 1) begin
      for (j = 0; j < VLEN; j = j + 1) begin
        acc = {ACC_W{1'b0}};

        for (kk = 0; kk < K; kk = kk + 1) begin
          a_idx = i*K + kk;
          b_idx = kk*VLEN + j;

          a_q_s = A_q[a_idx*QBW +: QBW];
          b_q_s = B_q[b_idx*QBW +: QBW];

          a_centered = $signed({a_q_s[QBW-1], a_q_s}) -
                       $signed({zp_A_s[QBW-1], zp_A_s});
          b_centered = $signed({b_q_s[QBW-1], b_q_s}) -
                       $signed({zp_B_s[QBW-1], zp_B_s});

          product = a_centered * b_centered;
          acc = acc + product;
        end

        C_acc[(i*VLEN+j)*ACC_W +: ACC_W] = acc;
      end
    end
  end

endmodule