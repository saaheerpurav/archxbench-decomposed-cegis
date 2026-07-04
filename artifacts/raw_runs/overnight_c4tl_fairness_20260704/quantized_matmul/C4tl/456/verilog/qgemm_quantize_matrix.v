`timescale 1ns/1ps

module qgemm_quantize_matrix #(
  parameter ELEMS = 512,
  parameter FP_W = 32,
  parameter QBW = 8,
  parameter SCALE_W = 16,
  parameter SCALE_Q = 15
)(
  input [ELEMS*FP_W-1:0] fp_in,
  input [SCALE_W-1:0] scale,
  input [QBW-1:0] zp,
  output reg [ELEMS*QBW-1:0] q_out
);

  integer i;
  reg [FP_W-1:0] fp_bits;
  reg [QBW-1:0] q_bits;

  function real fp32_to_real;
    input [31:0] bits;
    integer sign;
    integer exp;
    integer frac;
    integer n;
    real mant;
    real pwr;
    begin
      sign = bits[31] ? -1 : 1;
      exp = bits[30:23];
      frac = bits[22:0];

      if (exp == 0 && frac == 0) begin
        fp32_to_real = 0.0;
      end else if (exp == 0) begin
        mant = frac;
        pwr = 1.0;
        for (n = 0; n < 149; n = n + 1)
          pwr = pwr / 2.0;
        fp32_to_real = sign * mant * pwr;
      end else if (exp == 255) begin
        fp32_to_real = 0.0;
      end else begin
        mant = 1.0 + (frac / 8388608.0);
        pwr = 1.0;
        if (exp >= 127) begin
          for (n = 0; n < exp - 127; n = n + 1)
            pwr = pwr * 2.0;
        end else begin
          for (n = 0; n < 127 - exp; n = n + 1)
            pwr = pwr / 2.0;
        end
        fp32_to_real = sign * mant * pwr;
      end
    end
  endfunction

  function integer round_real_to_int;
    input real val;
    begin
      if (val >= 0.0)
        round_real_to_int = $rtoi(val + 0.5);
      else
        round_real_to_int = $rtoi(val - 0.5);
    end
  endfunction

  function [QBW-1:0] quantize_one;
    input [31:0] bits;
    input [SCALE_W-1:0] scale_i;
    input [QBW-1:0] zp_i;
    real fp_val;
    real scale_val;
    integer q_int;
    integer q_min;
    integer q_max;
    begin
      fp_val = fp32_to_real(bits);
      scale_val = scale_i;
      scale_val = scale_val / (1 << SCALE_Q);

      if (scale_i == 0)
        q_int = zp_i;
      else
        q_int = round_real_to_int(fp_val / scale_val) + zp_i;

      q_min = 0;
      q_max = (1 << QBW) - 1;

      if (q_int < q_min)
        q_int = q_min;
      else if (q_int > q_max)
        q_int = q_max;

      quantize_one = q_int[QBW-1:0];
    end
  endfunction

  always @* begin
    q_out = {ELEMS*QBW{1'b0}};
    for (i = 0; i < ELEMS; i = i + 1) begin
      fp_bits = fp_in[ELEMS*FP_W-1 - i*FP_W -: FP_W];
      q_bits = quantize_one(fp_bits, scale, zp);
      q_out[ELEMS*QBW-1 - i*QBW -: QBW] = q_bits;
    end
  end

endmodule