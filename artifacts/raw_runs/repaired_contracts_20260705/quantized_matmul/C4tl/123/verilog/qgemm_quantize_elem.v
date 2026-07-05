`timescale 1ns/1ps

module qgemm_quantize_elem #(
  parameter FP_W = 32,
  parameter QBW = 8,
  parameter SCALE_W = 16,
  parameter SCALE_Q = 15
)(
  input [FP_W-1:0] fp_in,
  input [SCALE_W-1:0] scale,
  input [QBW-1:0] zp,
  output reg [QBW-1:0] q_out
);

  function real fp32_to_real;
    input [31:0] bits;
    reg sign;
    integer exp;
    integer mant;
    real frac;
    real pow2;
    integer n;
    begin
      sign = bits[31];
      exp = bits[30:23];
      mant = bits[22:0];

      if (exp == 255) begin
        fp32_to_real = sign ? -3.4028234663852886e38 : 3.4028234663852886e38;
      end else if (exp == 0) begin
        frac = mant / 8388608.0;
        pow2 = 1.0;
        for (n = 0; n < 126; n = n + 1)
          pow2 = pow2 / 2.0;
        fp32_to_real = frac * pow2;
        if (sign)
          fp32_to_real = -fp32_to_real;
      end else begin
        frac = 1.0 + (mant / 8388608.0);
        if (exp >= 127) begin
          pow2 = 1.0;
          for (n = 0; n < exp-127; n = n + 1)
            pow2 = pow2 * 2.0;
        end else begin
          pow2 = 1.0;
          for (n = 0; n < 127-exp; n = n + 1)
            pow2 = pow2 / 2.0;
        end
        fp32_to_real = frac * pow2;
        if (sign)
          fp32_to_real = -fp32_to_real;
      end
    end
  endfunction

  function integer round_nearest;
    input real x;
    integer base;
    real diff;
    begin
      if (x >= 0.0) begin
        base = x;
        diff = x - base;
        round_nearest = (diff >= 0.5) ? base + 1 : base;
      end else begin
        base = -x;
        diff = (-x) - base;
        round_nearest = (diff >= 0.5) ? -(base + 1) : -base;
      end
    end
  endfunction

  real fp_val;
  real scale_val;
  integer q_int;
  integer max_q;

  always @* begin
    max_q = (1 << QBW) - 1;
    scale_val = scale / (1.0 * (1 << SCALE_Q));

    if (scale == 0) begin
      q_int = zp;
    end else begin
      fp_val = fp32_to_real(fp_in);
      q_int = round_nearest(fp_val / scale_val) + zp;
    end

    if (q_int < 0)
      q_out = {QBW{1'b0}};
    else if (q_int > max_q)
      q_out = max_q[QBW-1:0];
    else
      q_out = q_int[QBW-1:0];
  end

endmodule