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
    integer exp;
    integer frac;
    real mant;
    real val;
    begin
      exp = bits[30:23];
      frac = bits[22:0];
      if (exp == 0 && frac == 0) begin
        val = 0.0;
      end else if (exp == 0) begin
        mant = frac / 8388608.0;
        val = mant * pow2_real(-126);
      end else begin
        mant = 1.0 + (frac / 8388608.0);
        val = mant * pow2_real(exp - 127);
      end
      if (bits[31])
        fp32_to_real = -val;
      else
        fp32_to_real = val;
    end
  endfunction

  function real pow2_real;
    input integer e;
    integer i;
    real r;
    begin
      r = 1.0;
      if (e >= 0) begin
        for (i = 0; i < e; i = i + 1)
          r = r * 2.0;
      end else begin
        for (i = 0; i < -e; i = i + 1)
          r = r / 2.0;
      end
      pow2_real = r;
    end
  endfunction

  function integer round_nearest_even;
    input real x;
    integer lower;
    real frac;
    integer even_lower;
    begin
      if (x >= 0.0) begin
        lower = $rtoi(x);
        frac = x - lower;
        if (frac > 0.5)
          round_nearest_even = lower + 1;
        else if (frac < 0.5)
          round_nearest_even = lower;
        else begin
          even_lower = lower - ((lower / 2) * 2);
          round_nearest_even = even_lower ? lower + 1 : lower;
        end
      end else begin
        round_nearest_even = -round_nearest_even(-x);
      end
    end
  endfunction

  real fp_val;
  real scale_val;
  integer q_int;
  integer zp_int;

  always @* begin
    fp_val = fp32_to_real(fp_in);
    scale_val = scale / pow2_real(SCALE_Q);
    zp_int = $signed(zp);

    if (scale == 0)
      q_int = zp_int;
    else
      q_int = round_nearest_even(fp_val / scale_val) + zp_int;

    q_out = q_int[QBW-1:0];
  end

endmodule