`timescale 1ns/1ps

module qgemm_dequant #(
  parameter VLEN    = 8,
  parameter FP_W    = 32,
  parameter ACC_W   = 32,
  parameter SCALE_W = 16,
  parameter SCALE_Q = 15
)(
  input  wire [VLEN*VLEN*ACC_W-1:0] C_acc,
  input  wire [SCALE_W-1:0]         scale_A,
  input  wire [SCALE_W-1:0]         scale_B,
  output reg  [VLEN*VLEN*FP_W-1:0]  C_fp
);

  function real q_to_real;
    input [SCALE_W-1:0] q;
    integer s;
    real denom;
    begin
      denom = 1.0;
      for (s = 0; s < SCALE_Q; s = s + 1)
        denom = denom * 2.0;

      q_to_real = q / denom;
    end
  endfunction

  function [31:0] real_to_fp32;
    input real value;

    reg sign;
    real abs_value;
    real norm;
    integer exp_unbiased;
    integer exp_biased;
    integer frac;
    begin
      if (value == 0.0) begin
        real_to_fp32 = 32'h00000000;
      end else begin
        sign = (value < 0.0);
        abs_value = sign ? -value : value;

        norm = abs_value;
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
          frac = ((norm - 1.0) * 8388608.0) + 0.5;

          if (frac >= 8388608) begin
            frac = 0;
            exp_biased = exp_biased + 1;
          end

          if (exp_biased >= 255)
            real_to_fp32 = {sign, 8'hff, 23'b0};
          else
            real_to_fp32 = {sign, exp_biased[7:0], frac[22:0]};
        end
      end
    end
  endfunction

  integer idx;
  reg signed [ACC_W-1:0] acc_signed;
  real scale_a_real;
  real scale_b_real;
  real result_real;

  always @* begin
    scale_a_real = q_to_real(scale_A);
    scale_b_real = q_to_real(scale_B);

    C_fp = {VLEN*VLEN*FP_W{1'b0}};

    for (idx = 0; idx < VLEN*VLEN; idx = idx + 1) begin
      acc_signed = C_acc[idx*ACC_W +: ACC_W];
      result_real = acc_signed * scale_a_real * scale_b_real;
      C_fp[idx*FP_W +: FP_W] = real_to_fp32(result_real);
    end
  end

endmodule