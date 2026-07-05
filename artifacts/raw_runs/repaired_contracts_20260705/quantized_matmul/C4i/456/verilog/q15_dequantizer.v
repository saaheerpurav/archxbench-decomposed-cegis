`timescale 1ns/1ps

module q15_dequantizer #(
  parameter FP_W = 32,
  parameter ACC_W = 32,
  parameter SCALE_W = 16,
  parameter SCALE_Q = 15
)(
  input signed [ACC_W-1:0] acc,
  input [SCALE_W-1:0] scale_A,
  input [SCALE_W-1:0] scale_B,
  output reg [FP_W-1:0] fp_out
);

  reg signed [95:0] acc_ext;
  reg [95:0] scale_a_ext;
  reg [95:0] scale_b_ext;
  reg [95:0] scale_prod;
  reg signed [95:0] prod_signed;
  reg [95:0] prod_abs;

  reg sign_bit;
  integer msb;
  integer exp_unbiased;
  integer exp_biased;
  integer shift;
  integer i;

  reg [95:0] sig;
  reg [95:0] rem;
  reg [95:0] half;
  reg round_up;

  always @* begin
    acc_ext = {{(96-ACC_W){acc[ACC_W-1]}}, acc};
    scale_a_ext = {{(96-SCALE_W){1'b0}}, scale_A};
    scale_b_ext = {{(96-SCALE_W){1'b0}}, scale_B};

    scale_prod = scale_a_ext * scale_b_ext;
    prod_signed = acc_ext * $signed({1'b0, scale_prod[94:0]});

    sign_bit = prod_signed < 0;
    prod_abs = sign_bit ? -prod_signed : prod_signed;

    if (prod_abs == 0) begin
      fp_out = 32'h00000000;
    end else begin
      msb = 0;
      for (i = 0; i < 96; i = i + 1)
        if (prod_abs[i])
          msb = i;

      exp_unbiased = msb - (2 * SCALE_Q);
      exp_biased = exp_unbiased + 127;
      shift = msb - 23;

      if (shift > 0) begin
        sig = prod_abs >> shift;
        rem = prod_abs - (sig << shift);
        half = 96'd1 << (shift - 1);
        round_up = (rem >= half);
        sig = sig + round_up;
      end else begin
        sig = prod_abs << (-shift);
      end

      if (sig[24]) begin
        sig = sig >> 1;
        exp_biased = exp_biased + 1;
      end

      if (exp_biased >= 255)
        fp_out = {sign_bit, 8'hff, 23'b0};
      else if (exp_biased <= 0)
        fp_out = {sign_bit, 31'b0};
      else
        fp_out = {sign_bit, exp_biased[7:0], sig[22:0]};
    end
  end

endmodule