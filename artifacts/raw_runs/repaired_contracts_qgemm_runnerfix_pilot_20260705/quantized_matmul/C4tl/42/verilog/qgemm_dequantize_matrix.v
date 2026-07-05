`timescale 1ns/1ps

module qgemm_dequantize_matrix #(
  parameter ELEMS = 64,
  parameter FP_W = 32,
  parameter ACC_W = 32,
  parameter SCALE_W = 16,
  parameter SCALE_Q = 15
)(
  input [ELEMS*ACC_W-1:0] C_acc,
  input [SCALE_W-1:0] scale_A,
  input [SCALE_W-1:0] scale_B,
  output reg [ELEMS*FP_W-1:0] C_fp
);

  function real pow2_real;
    input integer e;
    integer i;
    real r;
    begin
      r = 1.0;
      if (e >= 0) begin
        for (i = 0; i < e; i = i + 1)
          r = r * 2.0;
      end else begin
        for (i = 0; i < -e; i = i + 1)
          r = r / 2.0;
      end
      pow2_real = r;
    end
  endfunction

  function [31:0] real_to_fp32;
    input real value;
    real abs_v;
    real norm;
    real frac_r;
    integer sign;
    integer exp_unbiased;
    integer exp_biased;
    integer mant;
    begin
      if (value == 0.0) begin
        real_to_fp32 = 32'h00000000;
      end else begin
        sign = (value < 0.0);
        abs_v = sign ? -value : value;
        exp_unbiased = 0;
        norm = abs_v;

        if (norm >= 2.0) begin
          while (norm >= 2.0) begin
            norm = norm / 2.0;
            exp_unbiased = exp_unbiased + 1;
          end
        end else begin
          while (norm < 1.0) begin
            norm = norm * 2.0;
            exp_unbiased = exp_unbiased - 1;
          end
        end

        exp_biased = exp_unbiased + 127;

        if (exp_biased <= 0) begin
          frac_r = abs_v / pow2_real(-149);
          mant = round_nearest_even(frac_r);
          if (mant <= 0)
            real_to_fp32 = {sign[0], 31'h00000000};
          else if (mant >= 8388608)
            real_to_fp32 = {sign[0], 8'd1, 23'd0};
          else
            real_to_fp32 = {sign[0], 8'd0, mant[22:0]};
        end else if (exp_biased >= 255) begin
          real_to_fp32 = {sign[0], 8'hff, 23'd0};
        end else begin
          frac_r = (norm - 1.0) * 8388608.0;
          mant = round_nearest_even(frac_r);
          if (mant >= 8388608) begin
            mant = 0;
            exp_biased = exp_biased + 1;
          end
          if (exp_biased >= 255)
            real_to_fp32 = {sign[0], 8'hff, 23'd0};
          else
            real_to_fp32 = {sign[0], exp_biased[7:0], mant[22:0]};
        end
      end
    end
  endfunction

  function integer round_nearest_even;
    input real x;
    integer lower;
    real frac;
    integer even_lower;
    begin
      if (x >= 0.0) begin
        lower = $rtoi(x);
        frac = x - lower;
        if (frac > 0.5)
          round_nearest_even = lower + 1;
        else if (frac < 0.5)
          round_nearest_even = lower;
        else begin
          even_lower = lower - ((lower / 2) * 2);
          round_nearest_even = even_lower ? lower + 1 : lower;
        end
      end else begin
        round_nearest_even = -round_nearest_even(-x);
      end
    end
  endfunction

  integer idx;
  integer acc_s;
  real sA;
  real sB;
  real out_val;

  always @* begin
    sA = scale_A / pow2_real(SCALE_Q);
    sB = scale_B / pow2_real(SCALE_Q);
    C_fp = {ELEMS*FP_W{1'b0}};

    for (idx = 0; idx < ELEMS; idx = idx + 1) begin
      acc_s = $signed(C_acc[idx*ACC_W +: ACC_W]);
      out_val = acc_s * sA * sB;
      C_fp[idx*FP_W +: FP_W] = real_to_fp32(out_val);
    end
  end

endmodule