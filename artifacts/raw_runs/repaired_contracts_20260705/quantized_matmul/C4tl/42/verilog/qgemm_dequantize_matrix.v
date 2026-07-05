`timescale 1ns/1ps

module qgemm_dequantize_matrix #(
  parameter ELEMS = 64,
  parameter FP_W = 32,
  parameter ACC_W = 32,
  parameter SCALE_W = 16,
  parameter SCALE_Q = 15
)(
  input signed [ELEMS*ACC_W-1:0] C_acc,
  input [SCALE_W-1:0] scale_A,
  input [SCALE_W-1:0] scale_B,
  output reg [ELEMS*FP_W-1:0] C_fp
);

  integer idx;
  real val;
  real scale_val;
  reg signed [ACC_W-1:0] acc_val;

  function [31:0] real_to_fp32;
    input real x;
    integer sign;
    integer exp;
    integer mant;
    integer shift;
    real ax;
    real norm;
    real frac;
    real rounded;
    begin
      if (x == 0.0) begin
        real_to_fp32 = 32'h00000000;
      end else begin
        sign = (x < 0.0);
        ax = sign ? -x : x;
        exp = 127;
        norm = ax;

        while (norm >= 2.0) begin
          norm = norm / 2.0;
          exp = exp + 1;
        end

        while (norm < 1.0) begin
          norm = norm * 2.0;
          exp = exp - 1;
        end

        if (exp <= 0) begin
          norm = ax;
          for (shift = 0; shift < 126; shift = shift + 1)
            norm = norm * 2.0;
          rounded = norm * 8388608.0;
          mant = $rtoi(rounded + 0.5);
          real_to_fp32 = {sign[0], 8'h00, mant[22:0]};
        end else if (exp >= 255) begin
          real_to_fp32 = {sign[0], 8'hff, 23'h000000};
        end else begin
          frac = norm - 1.0;
          rounded = frac * 8388608.0;
          mant = $rtoi(rounded + 0.5);

          if (mant >= 8388608) begin
            mant = 0;
            exp = exp + 1;
          end

          if (exp >= 255)
            real_to_fp32 = {sign[0], 8'hff, 23'h000000};
          else
            real_to_fp32 = {sign[0], exp[7:0], mant[22:0]};
        end
      end
    end
  endfunction

  always @* begin
    scale_val = (scale_A * scale_B) / (1.0 * (1 << SCALE_Q) * (1 << SCALE_Q));

    for (idx = 0; idx < ELEMS; idx = idx + 1) begin
      acc_val = C_acc[idx*ACC_W +: ACC_W];
      val = acc_val * scale_val;
      C_fp[idx*FP_W +: FP_W] = real_to_fp32(val);
    end
  end

endmodule