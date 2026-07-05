`timescale 1ns/1ps

module qgemm_dequantize_matrix #(
  parameter ELEMS = 64,
  parameter ACC_W = 32,
  parameter FP_W = 32,
  parameter SCALE_W = 16,
  parameter SCALE_Q = 15
)(
  input [ELEMS*ACC_W-1:0] C_acc,
  input [SCALE_W-1:0] scale_A,
  input [SCALE_W-1:0] scale_B,
  output reg [ELEMS*FP_W-1:0] C_fp
);

  integer i;
  reg signed [ACC_W-1:0] acc_word;

  function [31:0] real_to_fp32;
    input real value;
    real v;
    real norm;
    real scaled;
    real frac_real;
    integer sign;
    integer exp;
    integer exp_bits;
    integer mant;
    integer rounded;
    begin
      if (value == 0.0) begin
        real_to_fp32 = 32'h00000000;
      end else begin
        if (value < 0.0) begin
          sign = 1;
          v = -value;
        end else begin
          sign = 0;
          v = value;
        end

        exp = 0;
        norm = v;

        if (norm >= 2.0) begin
          while (norm >= 2.0) begin
            norm = norm / 2.0;
            exp = exp + 1;
          end
        end else begin
          while (norm < 1.0 && exp > -149) begin
            norm = norm * 2.0;
            exp = exp - 1;
          end
        end

        if (exp < -126) begin
          scaled = v / (2.0 ** (-149));
          rounded = scaled + 0.5;
          if (rounded <= 0)
            real_to_fp32 = {sign[0], 31'b0};
          else if (rounded >= 8388608)
            real_to_fp32 = {sign[0], 8'h01, 23'b0};
          else
            real_to_fp32 = {sign[0], 8'h00, rounded[22:0]};
        end else if (exp > 127) begin
          real_to_fp32 = {sign[0], 8'hff, 23'b0};
        end else begin
          frac_real = (norm - 1.0) * 8388608.0;
          rounded = frac_real + 0.5;

          if (rounded >= 8388608) begin
            rounded = 0;
            exp = exp + 1;
          end

          if (exp > 127) begin
            real_to_fp32 = {sign[0], 8'hff, 23'b0};
          end else begin
            exp_bits = exp + 127;
            mant = rounded;
            real_to_fp32 = {sign[0], exp_bits[7:0], mant[22:0]};
          end
        end
      end
    end
  endfunction

  function [31:0] dequant_one;
    input signed [ACC_W-1:0] acc;
    input [SCALE_W-1:0] sc_a;
    input [SCALE_W-1:0] sc_b;
    real val;
    begin
      val = acc * (sc_a / (2.0 ** SCALE_Q)) * (sc_b / (2.0 ** SCALE_Q));
      dequant_one = real_to_fp32(val);
    end
  endfunction

  always @* begin
    C_fp = {ELEMS*FP_W{1'b0}};
    for (i = 0; i < ELEMS; i = i + 1) begin
      acc_word = C_acc[i*ACC_W +: ACC_W];
      C_fp[i*FP_W +: FP_W] = dequant_one(acc_word, scale_A, scale_B);
    end
  end

endmodule