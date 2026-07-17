`timescale 1ns/1ps

module fp_hpf_fir_dot #(
    parameter TAP_CNT = 101
) (
    input wire [TAP_CNT*32-1:0] samples,
    input wire [TAP_CNT*32-1:0] coeffs,
    output wire [31:0] result
);
  integer i;
  real acc;
  real prod;
  reg [31:0] result_r;

  function real fp32_to_real;
    input [31:0] bits;
    integer sign;
    integer exp;
    integer mant;
    real frac;
    real pow2;
    integer e;
    begin
      sign = bits[31];
      exp = bits[30:23];
      mant = bits[22:0];

      if (exp == 0 && mant == 0) begin
        fp32_to_real = 0.0;
      end else if (exp == 0) begin
        frac = mant / 8388608.0;
        pow2 = 1.0;
        for (e = 0; e < 126; e = e + 1)
          pow2 = pow2 / 2.0;
        fp32_to_real = frac * pow2;
        if (sign)
          fp32_to_real = -fp32_to_real;
      end else begin
        frac = 1.0 + (mant / 8388608.0);
        pow2 = 1.0;
        if (exp >= 127) begin
          for (e = 0; e < exp - 127; e = e + 1)
            pow2 = pow2 * 2.0;
        end else begin
          for (e = 0; e < 127 - exp; e = e + 1)
            pow2 = pow2 / 2.0;
        end
        fp32_to_real = frac * pow2;
        if (sign)
          fp32_to_real = -fp32_to_real;
      end
    end
  endfunction

  function [31:0] real_to_fp32;
    input real val_in;
    real val;
    real frac;
    real mant_real;
    integer sign;
    integer exp_unbiased;
    integer exp_biased;
    integer mant;
    integer i_norm;
    begin
      val = val_in;
      sign = 0;
      if (val < 0.0) begin
        sign = 1;
        val = -val;
      end

      if (val == 0.0) begin
        real_to_fp32 = 32'h00000000;
      end else begin
        exp_unbiased = 0;

        for (i_norm = 0; i_norm < 300 && val >= 2.0; i_norm = i_norm + 1) begin
          val = val / 2.0;
          exp_unbiased = exp_unbiased + 1;
        end

        for (i_norm = 0; i_norm < 300 && val < 1.0; i_norm = i_norm + 1) begin
          val = val * 2.0;
          exp_unbiased = exp_unbiased - 1;
        end

        exp_biased = exp_unbiased + 127;

        if (exp_biased <= 0) begin
          real_to_fp32 = {sign[0], 31'h00000000};
        end else if (exp_biased >= 255) begin
          real_to_fp32 = {sign[0], 8'hfe, 23'h7fffff};
        end else begin
          frac = val - 1.0;
          mant_real = frac * 8388608.0;
          mant = mant_real + 0.5;

          if (mant >= 8388608) begin
            mant = 0;
            exp_biased = exp_biased + 1;
          end

          if (exp_biased >= 255)
            real_to_fp32 = {sign[0], 8'hfe, 23'h7fffff};
          else
            real_to_fp32 = {sign[0], exp_biased[7:0], mant[22:0]};
        end
      end
    end
  endfunction

  always @* begin
    acc = 0.0;
    for (i = 0; i < TAP_CNT; i = i + 1) begin
      prod = fp32_to_real(samples[(TAP_CNT-1-i)*32 +: 32]) * fp32_to_real(coeffs[i*32 +: 32]);
      acc = acc + prod;
    end
    result_r = real_to_fp32(acc);
  end

  assign result = result_r;
endmodule