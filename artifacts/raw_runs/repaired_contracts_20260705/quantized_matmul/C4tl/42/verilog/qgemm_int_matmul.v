`timescale 1ns/1ps

module qgemm_int_matmul #(
  parameter VLEN = 8,
  parameter K = 64,
  parameter QBW = 8,
  parameter ACC_W = 32
)(
  input signed [VLEN*K*QBW-1:0] A_centered,
  input signed [K*VLEN*QBW-1:0] B_centered,
  output reg signed [VLEN*VLEN*ACC_W-1:0] C_acc
);

  integer i;
  integer j;
  integer kk;
  integer a_index;
  integer b_index;
  integer c_index;
  reg signed [QBW-1:0] a_val;
  reg signed [QBW-1:0] b_val;
  reg signed [ACC_W-1:0] acc;

  always @* begin
    for (i = 0; i < VLEN; i = i + 1) begin
      for (j = 0; j < VLEN; j = j + 1) begin
        acc = {ACC_W{1'b0}};

        for (kk = 0; kk < K; kk = kk + 1) begin
          a_index = i*K + kk;
          b_index = kk*VLEN + j;
          a_val = A_centered[a_index*QBW +: QBW];
          b_val = B_centered[b_index*QBW +: QBW];
          acc = acc + (a_val * b_val);
        end

        c_index = i*VLEN + j;
        C_acc[c_index*ACC_W +: ACC_W] = acc;
      end
    end
  end

endmodule