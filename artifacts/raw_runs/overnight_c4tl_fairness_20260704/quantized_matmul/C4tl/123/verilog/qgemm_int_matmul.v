`timescale 1ns/1ps

module qgemm_int_matmul #(
  parameter VLEN = 8,
  parameter K = 64,
  parameter QBW = 8,
  parameter ACC_W = 32
)(
  input [VLEN*K*QBW-1:0] A_centered,
  input [K*VLEN*QBW-1:0] B_centered,
  output reg [VLEN*VLEN*ACC_W-1:0] C_acc
);

  integer i;
  integer j;
  integer kk;
  reg signed [QBW-1:0] aval;
  reg signed [QBW-1:0] bval;
  reg signed [ACC_W-1:0] sum;

  always @* begin
    C_acc = {(VLEN*VLEN*ACC_W){1'b0}};

    for (i = 0; i < VLEN; i = i + 1) begin
      for (j = 0; j < VLEN; j = j + 1) begin
        sum = {ACC_W{1'b0}};

        for (kk = 0; kk < K; kk = kk + 1) begin
          aval = A_centered[(i*K + kk)*QBW +: QBW];
          bval = B_centered[(kk*VLEN + j)*QBW +: QBW];
          sum = sum + aval * bval;
        end

        C_acc[(i*VLEN + j)*ACC_W +: ACC_W] = sum;
      end
    end
  end

endmodule