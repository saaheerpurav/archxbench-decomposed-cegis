`timescale 1ns/1ps

module qgemm_dequantize_matrix #(
  parameter ELEMS = 64,
  parameter FP_W = 32,
  parameter ACC_W = 32,
  parameter SCALE_W = 16,
  parameter SCALE_Q = 15
)(
  input [ELEMS*ACC_W-1:0] acc_in,
  input [SCALE_W-1:0] scale_A,
  input [SCALE_W-1:0] scale_B,
  output reg [ELEMS*FP_W-1:0] fp_out
);

  integer i;
  reg signed [ACC_W-1:0] acc_bits;

  function [31:0] real_to_fp32;
    input real val;
    integer sign;
    integer exp_unbiased;
    integer exp_bits;
    integer mant_int;
    integer n;
    real abs_val;
    real norm;
    real frac;
    begin
      if (val == 0.0) begin
        real_to_fp32 = 32'h00000000;
      end else begin
        if (val < 0.0) begin
          sign = 1;
          abs_val = -val;
        end else begin
          sign = 0;
          abs_val = val;
        end

        norm = abs_val;
        exp_unbiased = 0;

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
          real_to_fp32 = {sign[0], 31'b0};
        end else if (exp_bits >= 255) begin
          real_to_fp32 = {sign[0], 8'hff, 23'b0};
        end else begin
          frac = norm - 1.0;
          mant_int = $rtoi(frac * 8388608.0 + 0.5);

          if (mant_int >= 8388608) begin
            mant_int = 0;
            exp_bits = exp_bits + 1;
          end

          if (exp_bits >= 255)
            real_to_fp32 = {sign[0], 8'hff, 23'b0};
          else
            real_to_fp32 = {sign[0], exp_bits[7:0], mant_int[22:0]};
        end
      end
    end
  endfunction

  function [31:0] dequantize_one;
    input signed [ACC_W-1:0] acc;
    input [SCALE_W-1:0] scale_a_i;
    input [SCALE_W-1:0] scale_b_i;
    real scale_a_real;
    real scale_b_real;
    real out_real;
    begin
      scale_a_real = scale_a_i;
      scale_b_real = scale_b_i;
      scale_a_real = scale_a_real / (1 << SCALE_Q);
      scale_b_real = scale_b_real / (1 << SCALE_Q);
      out_real = acc * scale_a_real * scale_b_real;
      dequantize_one = real_to_fp32(out_real);
    end
  endfunction

  always @* begin
    fp_out = {ELEMS*FP_W{1'b0}};
    for (i = 0; i < ELEMS; i = i + 1) begin
      acc_bits = acc_in[i*ACC_W +: ACC_W];
      fp_out[i*FP_W +: FP_W] = dequantize_one(acc_bits, scale_A, scale_B);
    end
  end

endmodule