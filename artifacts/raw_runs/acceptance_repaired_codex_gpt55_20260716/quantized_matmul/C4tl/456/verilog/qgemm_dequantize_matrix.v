`timescale 1ns/1ps

module qgemm_dequantize_matrix #(
  parameter VLEN = 8,
  parameter FP_W = 32,
  parameter ACC_W = 32,
  parameter SCALE_W = 16,
  parameter SCALE_Q = 15
)(
  input  [VLEN*VLEN*ACC_W-1:0] C_acc,
  input  [SCALE_W-1:0]          scale_A,
  input  [SCALE_W-1:0]          scale_B,
  output reg [VLEN*VLEN*FP_W-1:0] C_fp
);

  integer i;
  real scale_a_real;
  real scale_b_real;
  real scale_prod;
  real dequantized;

  function [31:0] real_to_fp32;
    input real x;
    reg sign;
    real ax;
    real norm;
    real frac_real;
    integer exp_unbiased;
    integer exp_biased;
    integer frac;
    begin
      if (x == 0.0) begin
        real_to_fp32 = 32'h00000000;
      end else begin
        sign = (x < 0.0);
        ax = sign ? -x : x;

        norm = ax;
        exp_unbiased = 0;

        while (norm >= 2.0) begin
          norm = norm / 2.0;
          exp_unbiased = exp_unbiased + 1;
        end

        while (norm < 1.0) begin
          norm = norm * 2.0;
          exp_unbiased = exp_unbiased - 1;
        end

        exp_biased = exp_unbiased + 127;

        if (exp_biased <= 0) begin
          real_to_fp32 = {sign, 31'b0};
        end else if (exp_biased >= 255) begin
          real_to_fp32 = {sign, 8'hff, 23'b0};
        end else begin
          frac_real = (norm - 1.0) * 8388608.0;
          frac = frac_real + 0.5;

          if (frac >= 8388608) begin
            frac = 0;
            exp_biased = exp_biased + 1;
          end

          if (exp_biased >= 255) begin
            real_to_fp32 = {sign, 8'hff, 23'b0};
          end else begin
            real_to_fp32 = {sign, exp_biased[7:0], frac[22:0]};
          end
        end
      end
    end
  endfunction

  always @* begin
    C_fp = {VLEN*VLEN*FP_W{1'b0}};

    scale_a_real = $signed(scale_A) / (1.0 * (1 << SCALE_Q));
    scale_b_real = $signed(scale_B) / (1.0 * (1 << SCALE_Q));
    scale_prod = scale_a_real * scale_b_real;

    for (i = 0; i < VLEN*VLEN; i = i + 1) begin
      dequantized = $signed(C_acc[i*ACC_W +: ACC_W]) * scale_prod;
      C_fp[i*FP_W +: FP_W] = real_to_fp32(dequantized);
    end
  end

endmodule