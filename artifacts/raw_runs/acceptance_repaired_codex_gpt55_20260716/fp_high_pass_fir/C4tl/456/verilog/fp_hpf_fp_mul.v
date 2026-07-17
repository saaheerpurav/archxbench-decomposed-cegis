`timescale 1ns/1ps

module fp_hpf_fp_mul (
    input wire [31:0] a,
    input wire [31:0] b,
    output wire [31:0] y
);
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
      end else begin
        frac = (exp == 0) ? (mant / 8388608.0) : (1.0 + mant / 8388608.0);
        pow2 = 1.0;
        if (exp == 0)
          exp = 1;
        if (exp >= 127)
          for (e = 0; e < exp - 127; e = e + 1) pow2 = pow2 * 2.0;
        else
          for (e = 0; e < 127 - exp; e = e + 1) pow2 = pow2 / 2.0;
        fp32_to_real = sign ? -(frac * pow2) : (frac * pow2);
      end
    end
  endfunction

  function [31:0] real_to_fp32;
    input real v;
    real val;
    real frac;
    integer sign;
    integer exp_unbiased;
    integer exp_biased;
    integer mant;
    integer k;
    begin
      val = v;
      sign = 0;
      if (val < 0.0) begin sign = 1; val = -val; end
      if (val == 0.0) begin
        real_to_fp32 = 32'h00000000;
      end else begin
        exp_unbiased = 0;
        for (k = 0; k < 300 && val >= 2.0; k = k + 1) begin val = val / 2.0; exp_unbiased = exp_unbiased + 1; end
        for (k = 0; k < 300 && val < 1.0; k = k + 1) begin val = val * 2.0; exp_unbiased = exp_unbiased - 1; end
        exp_biased = exp_unbiased + 127;
        if (exp_biased <= 0) begin
          real_to_fp32 = {sign[0], 31'h00000000};
        end else if (exp_biased >= 255) begin
          real_to_fp32 = {sign[0], 8'hfe, 23'h7fffff};
        end else begin
          frac = val - 1.0;
          mant = frac * 8388608.0 + 0.5;
          if (mant >= 8388608) begin mant = 0; exp_biased = exp_biased + 1; end
          real_to_fp32 = {sign[0], exp_biased[7:0], mant[22:0]};
        end
      end
    end
  endfunction

  assign y = real_to_fp32(fp32_to_real(a) * fp32_to_real(b));
endmodule