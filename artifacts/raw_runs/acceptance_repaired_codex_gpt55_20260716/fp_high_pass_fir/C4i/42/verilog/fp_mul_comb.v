`timescale 1ns/1ps

module fp_mul_comb (
    input  wire [31:0] a,
    input  wire [31:0] b,
    output wire [31:0] y
);

  function real fp32_to_real;
    input [31:0] x;
    reg sign;
    reg [7:0] exp;
    reg [22:0] frac;
    real mant;
    integer e;
    begin
      sign = x[31];
      exp = x[30:23];
      frac = x[22:0];

      if (exp == 8'h00) begin
        if (frac == 23'd0) begin
          fp32_to_real = 0.0;
        end else begin
          mant = frac / 8388608.0;
          fp32_to_real = mant;
          for (e = 0; e < 126; e = e + 1)
            fp32_to_real = fp32_to_real / 2.0;
        end
      end else begin
        mant = 1.0 + (frac / 8388608.0);
        fp32_to_real = mant;
        if (exp >= 127) begin
          for (e = 0; e < exp - 127; e = e + 1)
            fp32_to_real = fp32_to_real * 2.0;
        end else begin
          for (e = 0; e < 127 - exp; e = e + 1)
            fp32_to_real = fp32_to_real / 2.0;
        end
      end

      if (sign)
        fp32_to_real = -fp32_to_real;
    end
  endfunction

  function [31:0] real_to_fp32;
    input real r;
    real v;
    real mant;
    real frac_scaled;
    integer sign;
    integer exp_unb;
    integer exp_biased;
    integer frac_int;
    begin
      if (r == 0.0) begin
        real_to_fp32 = 32'h00000000;
      end else begin
        sign = (r < 0.0);
        v = sign ? -r : r;

        exp_unb = 0;
        mant = v;

        while (mant >= 2.0) begin
          mant = mant / 2.0;
          exp_unb = exp_unb + 1;
        end

        while (mant < 1.0) begin
          mant = mant * 2.0;
          exp_unb = exp_unb - 1;
        end

        exp_biased = exp_unb + 127;

        if (exp_biased >= 255) begin
          real_to_fp32 = {sign[0], 8'hff, 23'h0};
        end else if (exp_biased <= 0) begin
          real_to_fp32 = {sign[0], 31'h0};
        end else begin
          frac_scaled = (mant - 1.0) * 8388608.0;
          frac_int = frac_scaled + 0.5;

          if (frac_int >= 8388608) begin
            frac_int = 0;
            exp_biased = exp_biased + 1;
          end

          if (exp_biased >= 255)
            real_to_fp32 = {sign[0], 8'hff, 23'h0};
          else
            real_to_fp32 = {sign[0], exp_biased[7:0], frac_int[22:0]};
        end
      end
    end
  endfunction

  assign y = real_to_fp32(fp32_to_real(a) * fp32_to_real(b));

endmodule