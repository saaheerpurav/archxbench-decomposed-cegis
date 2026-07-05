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

  integer i, j, kk;
  reg signed [QBW-1:0] a_raw;
  reg signed [QBW-1:0] b_raw;
  reg signed [ACC_W-1:0] a_center;
  reg signed [ACC_W-1:0] b_center;
  reg signed [ACC_W-1:0] acc;
  reg signed [QBW-1:0] zpa_s;
  reg signed [QBW-1:0] zpb_s;

  always @* begin
    C_acc = {VLEN*VLEN*ACC_W{1'b0}};
    zpa_s = zp_A;
    zpb_s = zp_B;

    for (i = 0; i < VLEN; i = i + 1) begin
      for (j = 0; j < VLEN; j = j + 1) begin
        acc = 0;
        for (kk = 0; kk < K; kk = kk + 1) begin
          a_raw = A_q[(i*K + kk)*QBW +: QBW];
          b_raw = B_q[(kk*VLEN + j)*QBW +: QBW];
          a_center = $signed(a_raw) - $signed(zpa_s);
          b_center = $signed(b_raw) - $signed(zpb_s);
          acc = acc + (a_center * b_center);
        end
        C_acc[(i*VLEN + j)*ACC_W +: ACC_W] = acc;
      end
    end
  end

endmodule