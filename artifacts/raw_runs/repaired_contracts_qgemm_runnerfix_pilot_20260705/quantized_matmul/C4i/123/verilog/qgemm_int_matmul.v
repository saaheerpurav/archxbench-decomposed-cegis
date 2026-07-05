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
  integer k;
  integer a_idx;
  integer b_idx;
  integer c_idx;

  reg signed [QBW-1:0] a_raw;
  reg signed [QBW-1:0] b_raw;
  reg signed [QBW-1:0] zpa_raw;
  reg signed [QBW-1:0] zpb_raw;

  reg signed [QBW:0] a_centered;
  reg signed [QBW:0] b_centered;
  reg signed [ACC_W-1:0] acc;

  always @* begin
    C_acc = {VLEN*VLEN*ACC_W{1'b0}};

    zpa_raw = zp_A;
    zpb_raw = zp_B;

    for (i = 0; i < VLEN; i = i + 1) begin
      for (j = 0; j < VLEN; j = j + 1) begin
        acc = {ACC_W{1'b0}};

        for (k = 0; k < K; k = k + 1) begin
          a_idx = i*K + k;
          b_idx = k*VLEN + j;

          a_raw = A_q[a_idx*QBW +: QBW];
          b_raw = B_q[b_idx*QBW +: QBW];

          a_centered = $signed(a_raw) - $signed(zpa_raw);
          b_centered = $signed(b_raw) - $signed(zpb_raw);

          acc = acc + (a_centered * b_centered);
        end

        c_idx = i*VLEN + j;
        C_acc[c_idx*ACC_W +: ACC_W] = acc;
      end
    end
  end

endmodule