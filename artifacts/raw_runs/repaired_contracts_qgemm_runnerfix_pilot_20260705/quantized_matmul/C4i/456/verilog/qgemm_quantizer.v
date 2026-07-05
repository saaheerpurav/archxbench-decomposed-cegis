`timescale 1ns/1ps

module qgemm_quantizer #(
  parameter NUM = 512,
  parameter FP_W = 32,
  parameter QBW = 8,
  parameter SCALE_W = 16,
  parameter SCALE_Q = 15
)(
  input  wire [NUM*FP_W-1:0] fp_in,
  input  wire [SCALE_W-1:0] scale,
  input  wire [QBW-1:0] zp,
  output reg  [NUM*QBW-1:0] q_out
);

  integer i;
  reg [31:0] fp_bits;
  integer q_int;
  real fp_val;
  real scale_val;

  function real pow2_real;
    input integer e;
    integer t;
    real r;
    begin
      r = 1.0;
      if (e >= 0) begin
        for (t = 0; t < e; t = t + 1)
          r = r * 2.0;
      end else begin
        for (t = 0; t < -e; t = t + 1)
          r = r / 2.0;
      end
      pow2_real = r;
    end
  endfunction

  function integer signed_zp_to_int;
    input [QBW-1:0] z;
    begin
      signed_zp_to_int = $signed(z);
    end
  endfunction

  function real fp32_to_real;
    input [31:0] bits;
    integer exp;
    integer frac;
    integer n;
    real mant;
    real val;
    begin
      exp = bits[30:23];
      frac = bits[22:0];

      if (exp == 0 && frac == 0) begin
        val = 0.0;
      end else if (exp == 0) begin
        mant = 0.0;
        for (n = 0; n < 23; n = n + 1) begin
          if (frac[n])
            mant = mant + pow2_real(n - 149);
        end
        val = mant;
      end else if (exp == 255) begin
        if (frac == 0)
          val = pow2_real(1024);
        else
          val = 0.0;
      end else begin
        mant = 1.0;
        for (n = 0; n < 23; n = n + 1) begin
          if (frac[n])
            mant = mant + pow2_real(n - 23);
        end
        val = mant * pow2_real(exp - 127);
      end

      if (bits[31])
        fp32_to_real = -val;
      else
        fp32_to_real = val;
    end
  endfunction

  function integer floor_real;
    input real x;
    integer t;
    begin
      t = $rtoi(x);
      if ((x < 0.0) && (x != t))
        floor_real = t - 1;
      else
        floor_real = t;
    end
  endfunction

  function integer round_even_real;
    input real x;
    integer flr;
    integer base;
    real frac;
    begin
      flr = floor_real(x);
      frac = x - flr;

      if (frac > 0.5) begin
        round_even_real = flr + 1;
      end else if (frac < 0.5) begin
        round_even_real = flr;
      end else begin
        base = flr;
        if ((base % 2) == 0)
          round_even_real = base;
        else
          round_even_real = base + 1;
      end
    end
  endfunction

  always @* begin
    q_out = {NUM*QBW{1'b0}};
    scale_val = $itor(scale) / pow2_real(SCALE_Q);

    for (i = 0; i < NUM; i = i + 1) begin
      fp_bits = fp_in[NUM*FP_W-1 - i*FP_W -: FP_W];

      if (scale == {SCALE_W{1'b0}}) begin
        q_int = signed_zp_to_int(zp);
      end else begin
        fp_val = fp32_to_real(fp_bits);
        q_int = round_even_real(fp_val / scale_val) + signed_zp_to_int(zp);
      end

      q_out[i*QBW +: QBW] = q_int[QBW-1:0];
    end
  end

endmodule