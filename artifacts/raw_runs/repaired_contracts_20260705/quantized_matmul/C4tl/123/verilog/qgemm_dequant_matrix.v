`timescale 1ns/1ps

module qgemm_dequant_matrix #(
  parameter VLEN = 8,
  parameter FP_W = 32,
  parameter ACC_W = 32,
  parameter SCALE_W = 16,
  parameter SCALE_Q = 15
)(
  input [VLEN*VLEN*ACC_W-1:0] C_acc,
  input [SCALE_W-1:0] scale_A,
  input [SCALE_W-1:0] scale_B,
  output reg [VLEN*VLEN*FP_W-1:0] C_fp
);

  function [31:0] real_to_fp32;
    input real value;
    reg sign;
    real abs_val;
    real norm;
    integer exp_unbiased;
    integer exp_bits;
    integer mant;
    real mant_real;
    begin
      if (value == 0.0) begin
        real_to_fp32 = 32'h00000000;
      end else begin
        sign = (value < 0.0);
        abs_val = sign ? -value : value;

        exp_unbiased = 0;
        norm = abs_val;

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
          mant_real = abs_val;
          while (exp_unbiased < 149) begin
            mant_real = mant_real * 2.0;
            exp_unbiased = exp_unbiased + 1;
          end
          mant = mant_real + 0.5;
          real_to_fp32 = {sign, 8'd0, mant[22:0]};
        end else if (exp_bits >= 255) begin
          real_to_fp32 = {sign, 8'hff, 23'd0};
        end else begin
          mant_real = (norm - 1.0) * 8388608.0;
          mant = mant_real + 0.5;

          if (mant >= 8388608) begin
            mant = 0;
            exp_bits = exp_bits + 1;
          end

          if (exp_bits >= 255)
            real_to_fp32 = {sign, 8'hff, 23'd0};
          else
            real_to_fp32 = {sign, exp_bits[7:0], mant[22:0]};
        end
      end
    end
  endfunction

  integer idx;
  integer signed_acc;
  real scale_val_A;
  real scale_val_B;
  real result;

  always @* begin
    scale_val_A = scale_A / (1.0 * (1 << SCALE_Q));
    scale_val_B = scale_B / (1.0 * (1 << SCALE_Q));

    for (idx = 0; idx < VLEN*VLEN; idx = idx + 1) begin
      signed_acc = C_acc[idx*ACC_W +: ACC_W];
      result = signed_acc * scale_val_A * scale_val_B;
      C_fp[idx*FP_W +: FP_W] = real_to_fp32(result);
    end
  end

endmodule