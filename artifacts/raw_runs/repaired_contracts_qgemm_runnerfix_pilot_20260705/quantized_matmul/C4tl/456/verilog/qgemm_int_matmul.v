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
  integer a_val;
  integer b_val;
  integer sum;
  reg [QBW-1:0] a_bits;
  reg [QBW-1:0] b_bits;

  always @* begin
    C_acc = {VLEN*VLEN*ACC_W{1'b0}};

    for (i = 0; i < VLEN; i = i + 1) begin
      for (j = 0; j < VLEN; j = j + 1) begin
        sum = 0;

        for (kk = 0; kk < K; kk = kk + 1) begin
          a_bits = A_q[(VLEN*K-1-(i*K+kk))*QBW +: QBW];
          b_bits = B_q[(K*VLEN-1-(kk*VLEN+j))*QBW +: QBW];

          a_val = $signed(a_bits) - $signed(zp_A);
          b_val = $signed(b_bits) - $signed(zp_B);
          sum = sum + (a_val * b_val);
        end

        C_acc[(i*VLEN+j)*ACC_W +: ACC_W] = sum[ACC_W-1:0];
      end
    end
  end

endmodule