`timescale 1ns/1ps

module fp_lpf_tap_mult (
    input  wire [31:0] sample,
    input  wire [31:0] coeff,
    output wire [31:0] product
);

  function real pow2;
    input integer e;
    integer i;
    real v;
    begin
      v = 1.0;
      if (e >= 0) begin
        for (i = 0; i < e; i = i + 1)
          v = v * 2.0;
      end else begin
        for (i = 0; i < -e; i = i + 1)
          v = v / 2.0;
      end
      pow2 = v;
    end
  endfunction

  function real fp32_to_real;
    input [31:0] bits;
    integer exp_unbiased;
    real mant;
    begin
      if (bits[30:0] == 31'd0) begin
        fp32_to_real = 0.0;
      end else if (bits[30:23] == 8'd0) begin
        mant = bits[22:0] / 8388608.0;
        fp32_to_real = bits[31] ? -mant * pow2(-126) : mant * pow2(-126);
      end else begin
        exp_unbiased = bits[30:23] - 127;
        mant = 1.0 + bits[22:0] / 8388608.0;
        fp32_to_real = bits[31] ? -mant * pow2(exp_unbiased)
                                :  mant * pow2(exp_unbiased);
      end
    end
  endfunction

  function real fixed_sample_to_real;
    input [31:0] bits;
    reg signed [31:0] s;
    begin
      s = bits;
      fixed_sample_to_real = s / 32768.0;
    end
  endfunction

  function [31:0] real_to_fp32;
    input real r;
    reg sign;
    real v;
    real scaled;
    integer exp_unbiased;
    integer exp_field;
    integer mant;
    begin
      if (r == 0.0) begin
        real_to_fp32 = 32'h00000000;
      end else begin
        sign = (r < 0.0);
        v = sign ? -r : r;
        exp_unbiased = 0;

        while (v >= 2.0) begin
          v = v / 2.0;
          exp_unbiased = exp_unbiased + 1;
        end

        while (v < 1.0) begin
          v = v * 2.0;
          exp_unbiased = exp_unbiased - 1;
        end

        exp_field = exp_unbiased + 127;
        scaled = (v - 1.0) * 8388608.0;
        mant = scaled + 0.5;

        if (mant >= 8388608) begin
          mant = 0;
          exp_field = exp_field + 1;
        end

        if (exp_field <= 0)
          real_to_fp32 = {sign, 31'd0};
        else if (exp_field >= 255)
          real_to_fp32 = {sign, 8'hfe, 23'h7fffff};
        else
          real_to_fp32 = {sign, exp_field[7:0], mant[22:0]};
      end
    end
  endfunction

  assign product = real_to_fp32(fixed_sample_to_real(sample) * fp32_to_real(coeff));

endmodule