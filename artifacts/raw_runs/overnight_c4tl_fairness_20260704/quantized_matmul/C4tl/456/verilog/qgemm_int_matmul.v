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
  integer kk;
  integer a_idx;
  integer b_idx;
  integer c_idx;
  integer a_val;
  integer b_val;
  integer sum;

  always @* begin
    C_acc = {VLEN*VLEN*ACC_W{1'b0}};

    for (i = 0; i < VLEN; i = i + 1) begin
      for (j = 0; j < VLEN; j = j + 1) begin
        sum = 0;

        for (kk = 0; kk < K; kk = kk + 1) begin
          a_idx = i*K + kk;
          b_idx = kk*VLEN + j;

          a_val = A_q[VLEN*K*QBW-1 - a_idx*QBW -: QBW];
          b_val = B_q[K*VLEN*QBW-1 - b_idx*QBW -: QBW];

          sum = sum + ((a_val - zp_A) * (b_val - zp_B));
        end

        c_idx = i*VLEN + j;
        C_acc[c_idx*ACC_W +: ACC_W] = sum[ACC_W-1:0];
      end
    end
  end

endmodule