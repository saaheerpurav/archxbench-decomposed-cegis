`timescale 1ns/1ps

module qgemm_int_matmul #(
  parameter VLEN  = 8,
  parameter K     = 64,
  parameter QBW   = 8,
  parameter ACC_W = 32
)(
  input  wire [VLEN*K*QBW-1:0]       A_q,
  input  wire [K*VLEN*QBW-1:0]       B_q,
  input  wire [QBW-1:0]              zp_A,
  input  wire [QBW-1:0]              zp_B,
  output reg  [VLEN*VLEN*ACC_W-1:0]  C_acc
);

  integer i;
  integer j;
  integer kk;

  reg signed [QBW:0]       a_val;
  reg signed [QBW:0]       b_val;
  reg signed [ACC_W-1:0]   acc;

  always @* begin
    C_acc = {VLEN*VLEN*ACC_W{1'b0}};

    for (i = 0; i < VLEN; i = i + 1) begin
      for (j = 0; j < VLEN; j = j + 1) begin
        acc = {ACC_W{1'b0}};

        for (kk = 0; kk < K; kk = kk + 1) begin
          a_val = $signed({1'b0, A_q[(i*K + kk)*QBW +: QBW]}) -
                  $signed({1'b0, zp_A});
          b_val = $signed({1'b0, B_q[(kk*VLEN + j)*QBW +: QBW]}) -
                  $signed({1'b0, zp_B});

          acc = acc + (a_val * b_val);
        end

        C_acc[(i*VLEN + j)*ACC_W +: ACC_W] = acc;
      end
    end
  end

endmodule