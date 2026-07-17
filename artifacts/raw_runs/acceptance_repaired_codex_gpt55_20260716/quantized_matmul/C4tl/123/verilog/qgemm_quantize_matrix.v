`timescale 1ns/1ps

module qgemm_quantize_matrix #(
  parameter ELEMS = 512,
  parameter FP_W = 32,
  parameter QBW = 8,
  parameter SCALE_W = 16,
  parameter SCALE_Q = 15
)(
  input  [ELEMS*FP_W-1:0] fp_in,
  input  [SCALE_W-1:0]    scale,
  input  [QBW-1:0]        zp,
  output reg [ELEMS*QBW-1:0] q_out
);

  integer i;
  reg [FP_W-1:0] fp_bits;
  integer q_int;
  integer zp_int;
  real fp_val;
  real scale_val;

  function real pow2;
    input integer e;
    integer n;
    real r;
    begin
      r = 1.0;
      if (e >= 0) begin
        for (n = 0; n < e; n = n + 1)
          r = r * 2.0;
      end else begin
        for (n = 0; n < -e; n = n + 1)
          r = r / 2.0;
      end
      pow2 = r;
    end
  endfunction

  function real fp32_to_real;
    input [31:0] bits;
    integer sign;
    integer exp;
    integer frac;
    real mant;
    begin
      sign = bits[31];
      exp  = bits[30:23];
      frac = bits[22:0];

      if (exp == 0 && frac == 0) begin
        fp32_to_real = 0.0;
      end else if (exp == 0) begin
        mant = frac / 8388608.0;
        fp32_to_real = mant * pow2(-126);
        if (sign)
          fp32_to_real = -fp32_to_real;
      end else if (exp == 255) begin
        fp32_to_real = 0.0;
      end else begin
        mant = 1.0 + (frac / 8388608.0);
        fp32_to_real = mant * pow2(exp - 127);
        if (sign)
          fp32_to_real = -fp32_to_real;
      end
    end
  endfunction

  function integer round_to_even;
    input real value;
    integer base;
    real frac;
    begin
      base = $rtoi(value);

      if (value >= 0.0) begin
        frac = value - base;

        if (frac > 0.5)
          round_to_even = base + 1;
        else if (frac < 0.5)
          round_to_even = base;
        else if ((base % 2) != 0)
          round_to_even = base + 1;
        else
          round_to_even = base;
      end else begin
        frac = base - value;

        if (frac > 0.5)
          round_to_even = base - 1;
        else if (frac < 0.5)
          round_to_even = base;
        else if ((base % 2) != 0)
          round_to_even = base - 1;
        else
          round_to_even = base;
      end
    end
  endfunction

  always @* begin
    q_out = {ELEMS*QBW{1'b0}};
    scale_val = $itor(scale) / pow2(SCALE_Q);
    zp_int = $signed(zp);

    for (i = 0; i < ELEMS; i = i + 1) begin
      fp_bits = fp_in[(ELEMS-1-i)*FP_W +: FP_W];
      fp_val = fp32_to_real(fp_bits);

      if (scale == 0)
        q_int = zp_int;
      else
        q_int = round_to_even(fp_val / scale_val) + zp_int;

      q_out[i*QBW +: QBW] = q_int[QBW-1:0];
    end
  end

endmodule