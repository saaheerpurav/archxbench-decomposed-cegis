`timescale 1ns/1ps

module fp32_q15_quantizer #(
  parameter FP_W = 32,
  parameter QBW = 8,
  parameter SCALE_W = 16,
  parameter SCALE_Q = 15
)(
  input  [FP_W-1:0] fp_in,
  input  [SCALE_W-1:0] scale_q15,
  input  [QBW-1:0] zero_point,
  output reg signed [QBW:0] centered_q
);

  integer q_raw;
  integer q_clamped;
  integer q_max;
  real fp_val;
  real scale_val;
  real ratio;

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
    integer sign;
    integer exp;
    integer mant;
    real frac;
    begin
      sign = bits[31] ? -1 : 1;
      exp  = bits[30:23];
      mant = bits[22:0];

      if (exp == 0 && mant == 0) begin
        fp32_to_real = 0.0;
      end else if (exp == 0) begin
        frac = mant / 8388608.0;
        fp32_to_real = sign * frac * pow2(-126);
      end else begin
        frac = 1.0 + (mant / 8388608.0);
        fp32_to_real = sign * frac * pow2(exp - 127);
      end
    end
  endfunction

  function integer round_real;
    input real x;
    integer t;
    begin
      if (x >= 0.0)
        t = $rtoi(x + 0.5);
      else
        t = $rtoi(x - 0.5);
      round_real = t;
    end
  endfunction

  always @* begin
    q_max = (1 << QBW) - 1;
    fp_val = fp32_to_real(fp_in);

    if (scale_q15 == 0) begin
      q_clamped = zero_point;
    end else begin
      scale_val = scale_q15 / (1.0 * (1 << SCALE_Q));
      ratio = fp_val / scale_val;

      if (ratio <= -zero_point) begin
        q_clamped = 0;
      end else if (ratio >= (q_max - zero_point)) begin
        q_clamped = q_max;
      end else begin
        q_raw = round_real(ratio) + zero_point;

        if (q_raw < 0)
          q_clamped = 0;
        else if (q_raw > q_max)
          q_clamped = q_max;
        else
          q_clamped = q_raw;
      end
    end

    centered_q = q_clamped - zero_point;
  end

endmodule