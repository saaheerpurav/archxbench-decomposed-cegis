`timescale 1ns/1ps

module qgemm_int_matmul #(
  parameter VLEN  = 8,
  parameter K     = 64,
  parameter QBW   = 8,
  parameter ACC_W = 32
)(
  input  [VLEN*K*QBW-1:0]       A_q,
  input  [K*VLEN*QBW-1:0]       B_q,
  input  [QBW-1:0]              zp_A,
  input  [QBW-1:0]              zp_B,
  output reg [VLEN*VLEN*ACC_W-1:0] C_acc
);

  integer i;
  integer j;
  integer kk;
  integer a_idx;
  integer b_idx;
  integer c_idx;

  reg signed [QBW:0] a_centered;
  reg signed [QBW:0] b_centered;
  reg signed [ACC_W-1:0] sum;

  always @* begin
    C_acc = {VLEN*VLEN*ACC_W{1'b0}};

    for (i = 0; i < VLEN; i = i + 1) begin
      for (j = 0; j < VLEN; j = j + 1) begin
        sum = {ACC_W{1'b0}};

        for (kk = 0; kk < K; kk = kk + 1) begin
          a_idx = i*K + kk;
          b_idx = kk*VLEN + j;

          a_centered =
            $signed({A_q[a_idx*QBW + QBW-1], A_q[a_idx*QBW +: QBW]}) -
            $signed({zp_A[QBW-1], zp_A});

          b_centered =
            $signed({B_q[b_idx*QBW + QBW-1], B_q[b_idx*QBW +: QBW]}) -
            $signed({zp_B[QBW-1], zp_B});

          sum = sum + (a_centered * b_centered);
        end

        c_idx = i*VLEN + j;
        C_acc[c_idx*ACC_W +: ACC_W] = sum;
      end
    end
  end

endmodule