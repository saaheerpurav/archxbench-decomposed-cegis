`timescale 1ns/1ps

module qgemm_dequantizer #(
  parameter VLEN = 8,
  parameter FP_W = 32,
  parameter ACC_W = 32,
  parameter SCALE_W = 16,
  parameter SCALE_Q = 15
)(
  input  [VLEN*VLEN*ACC_W-1:0] C_acc,
  input  [SCALE_W-1:0] scale_A,
  input  [SCALE_W-1:0] scale_B,
  output reg [VLEN*VLEN*FP_W-1:0] C_fp
);

  integer idx;
  integer signed acc_signed;
  real scale_a_real;
  real scale_b_real;
  real out_real;

  function real pow2;
    input integer exp;
    integer n;
    real value;
    begin
      value = 1.0;
      if (exp >= 0) begin
        for (n = 0; n < exp; n = n + 1)
          value = value * 2.0;
      end else begin
        for (n = 0; n < -exp; n = n + 1)
          value = value / 2.0;
      end
      pow2 = value;
    end
  endfunction

  function [31:0] real_to_fp32;
    input real value;
    integer sign;
    integer exponent;
    integer exp_raw;
    integer mant;
    real abs_val;
    real norm;
    real frac;
    begin
      if (value == 0.0) begin
        real_to_fp32 = 32'h00000000;
      end else begin
        if (value < 0.0) begin
          sign = 1;
          abs_val = -value;
        end else begin
          sign = 0;
          abs_val = value;
        end

        exponent = 0;
        norm = abs_val;

        while (norm >= 2.0) begin
          norm = norm / 2.0;
          exponent = exponent + 1;
        end

        while (norm < 1.0) begin
          norm = norm * 2.0;
          exponent = exponent - 1;
        end

        exp_raw = exponent + 127;

        if (exp_raw <= 0) begin
          mant = $rtoi(abs_val / pow2(-149) + 0.5);

          if (mant <= 0) begin
            real_to_fp32 = {sign[0], 31'h00000000};
          end else if (mant >= 8388608) begin
            real_to_fp32 = {sign[0], 8'h01, 23'h000000};
          end else begin
            real_to_fp32 = {sign[0], 8'h00, mant[22:0]};
          end
        end else if (exp_raw >= 255) begin
          real_to_fp32 = {sign[0], 8'hff, 23'h000000};
        end else begin
          frac = norm - 1.0;
          mant = $rtoi(frac * 8388608.0 + 0.5);

          if (mant >= 8388608) begin
            mant = 0;
            exp_raw = exp_raw + 1;
          end

          if (exp_raw >= 255)
            real_to_fp32 = {sign[0], 8'hff, 23'h000000};
          else
            real_to_fp32 = {sign[0], exp_raw[7:0], mant[22:0]};
        end
      end
    end
  endfunction

  always @* begin
    C_fp = {VLEN*VLEN*FP_W{1'b0}};

    scale_a_real = scale_A / pow2(SCALE_Q);
    scale_b_real = scale_B / pow2(SCALE_Q);

    for (idx = 0; idx < VLEN*VLEN; idx = idx + 1) begin
      acc_signed = $signed(C_acc[idx*ACC_W +: ACC_W]);
      out_real = acc_signed * scale_a_real * scale_b_real;
      C_fp[idx*FP_W +: FP_W] = real_to_fp32(out_real);
    end
  end

endmodule