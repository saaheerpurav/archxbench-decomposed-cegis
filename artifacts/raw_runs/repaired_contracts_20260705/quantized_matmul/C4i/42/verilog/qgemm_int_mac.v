`timescale 1ns/1ps

module qgemm_int_mac #(
  parameter VLEN  = 8,
  parameter K     = 64,
  parameter QBW   = 8,
  parameter ACC_W = 32
)(
  input  [VLEN*K*QBW-1:0]          A_q,
  input  [K*VLEN*QBW-1:0]          B_q,
  input  [QBW-1:0]                 zp_A,
  input  [QBW-1:0]                 zp_B,
  output reg [VLEN*VLEN*ACC_W-1:0] C_acc
);

  integer i;
  integer j;
  integer kk;

  reg signed [QBW-1:0] a_raw;
  reg signed [QBW-1:0] b_raw;
  reg signed [QBW-1:0] zp_a_raw;
  reg signed [QBW-1:0] zp_b_raw;

  integer a_val;
  integer b_val;
  integer zp_a_val;
  integer zp_b_val;
  integer acc;

  always @(*) begin
    C_acc = {(VLEN*VLEN*ACC_W){1'b0}};

    zp_a_raw = zp_A;
    zp_b_raw = zp_B;
    zp_a_val = zp_a_raw;
    zp_b_val = zp_b_raw;

    for (i = 0; i < VLEN; i = i + 1) begin
      for (j = 0; j < VLEN; j = j + 1) begin
        acc = 0;

        for (kk = 0; kk < K; kk = kk + 1) begin
          a_raw = A_q[(i*K + kk)*QBW +: QBW];
          b_raw = B_q[(kk*VLEN + j)*QBW +: QBW];

          a_val = a_raw;
          b_val = b_raw;

          acc = acc + ((a_val - zp_a_val) * (b_val - zp_b_val));
        end

        C_acc[(i*VLEN + j)*ACC_W +: ACC_W] = acc;
      end
    end
  end

endmodule