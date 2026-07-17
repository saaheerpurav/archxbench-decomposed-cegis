`timescale 1ns/1ps

module fp_fir_real_mac #(
    parameter TAP_CNT = 101
) (
    input  wire [TAP_CNT*32-1:0] sample_bus,
    input  wire [TAP_CNT*32-1:0] coeff_bus,
    input  wire [31:0] new_sample,
    output reg  [31:0] result
);

  integer i;
  reg [31:0] sample_word;
  reg [31:0] coeff_word;
  real acc;

  function real pow2;
    input integer e;
    integer k;
    real v;
    begin
      v = 1.0;
      if (e >= 0) begin
        for (k = 0; k < e; k = k + 1)
          v = v * 2.0;
      end else begin
        for (k = 0; k < -e; k = k + 1)
          v = v / 2.0;
      end
      pow2 = v;
    end
  endfunction

  function real fp32_to_real;
    input [31:0] bits;
    integer exp_bits;
    integer frac_bits;
    real val;
    begin
      exp_bits  = bits[30:23];
      frac_bits = bits[22:0];

      if (exp_bits == 0) begin
        val = frac_bits * pow2(-149);
      end else begin
        val = (8388608.0 + frac_bits) * pow2(exp_bits - 150);
      end

      if (bits[31])
        val = -val;

      fp32_to_real = val;
    end
  endfunction

  function [31:0] real_to_fp32;
    input real val;
    real ax;
    real norm;
    real frac_real;
    integer sign_bit;
    integer exp_unbiased;
    integer exp_bits;
    integer frac_bits;
    begin
      if (val == 0.0) begin
        real_to_fp32 = 32'h00000000;
      end else begin
        sign_bit = (val < 0.0);
        ax = sign_bit ? -val : val;

        exp_unbiased = 0;
        norm = ax;

        while (norm >= 2.0) begin
          norm = norm / 2.0;
          exp_unbiased = exp_unbiased + 1;
        end

        while (norm < 1.0) begin
          norm = norm * 2.0;
          exp_unbiased = exp_unbiased - 1;
        end

        exp_bits = exp_unbiased + 127;

        if (exp_bits <= 0) begin
          frac_real = ax / pow2(-149);
          frac_bits = frac_real + 0.5;

          if (frac_bits <= 0)
            real_to_fp32 = 32'h00000000;
          else if (frac_bits >= 8388608)
            real_to_fp32 = {sign_bit[0], 8'h01, 23'h000000};
          else
            real_to_fp32 = {sign_bit[0], 8'h00, frac_bits[22:0]};
        end else begin
          frac_real = (norm - 1.0) * 8388608.0;
          frac_bits = frac_real + 0.5;

          if (frac_bits >= 8388608) begin
            frac_bits = 0;
            exp_bits = exp_bits + 1;
          end

          if (exp_bits >= 255)
            real_to_fp32 = {sign_bit[0], 8'hfe, 23'h7fffff};
          else
            real_to_fp32 = {sign_bit[0], exp_bits[7:0], frac_bits[22:0]};
        end
      end
    end
  endfunction

  always @* begin
    acc = 0.0;

    for (i = 0; i < TAP_CNT; i = i + 1) begin
      if (i == 0)
        sample_word = new_sample;
      else
        sample_word = sample_bus[(i-1)*32 +: 32];

      coeff_word = coeff_bus[i*32 +: 32];
      acc = acc + fp32_to_real(sample_word) * fp32_to_real(coeff_word);
    end

    result = real_to_fp32(acc);
  end

endmodule