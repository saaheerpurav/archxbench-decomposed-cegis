`timescale 1ns/1ps

module qgemm_int_matmul #(
  parameter VLEN = 8,
  parameter K = 64,
  parameter QBW = 8,
  parameter ACC_W = 32
)(
  input [VLEN*K*QBW-1:0] A_q,
  input [K*VLEN*QBW-1:0] B_q,
  input [QBW-1:0] zp_A,
  input [QBW-1:0] zp_B,
  output reg [VLEN*VLEN*ACC_W-1:0] C_acc
);

  integer i;
  integer j;
  integer k;
  integer acc;
  integer a_center;
  integer b_center;
  integer zp_a_s;
  integer zp_b_s;
  reg signed [QBW-1:0] a_word;
  reg signed [QBW-1:0] b_word;

  always @* begin
    zp_a_s = $signed(zp_A);
    zp_b_s = $signed(zp_B);
    C_acc = {VLEN*VLEN*ACC_W{1'b0}};

    for (i = 0; i < VLEN; i = i + 1) begin
      for (j = 0; j < VLEN; j = j + 1) begin
        acc = 0;
        for (k = 0; k < K; k = k + 1) begin
          a_word = A_q[(i*K + k)*QBW +: QBW];
          b_word = B_q[(k*VLEN + j)*QBW +: QBW];
          a_center = $signed(a_word) - zp_a_s;
          b_center = $signed(b_word) - zp_b_s;
          acc = acc + (a_center * b_center);
        end
        C_acc[(i*VLEN + j)*ACC_W +: ACC_W] = acc[ACC_W-1:0];
      end
    end
  end

endmodule