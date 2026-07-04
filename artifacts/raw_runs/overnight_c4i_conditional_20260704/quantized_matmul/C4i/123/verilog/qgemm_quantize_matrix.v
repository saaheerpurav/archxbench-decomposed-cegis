`timescale 1ns/1ps

module qgemm_quantize_matrix #(
  parameter COUNT = 512,
  parameter FP_W = 32,
  parameter QBW = 8,
  parameter SCALE_W = 16,
  parameter SCALE_Q = 15
)(
  input  [COUNT*FP_W-1:0] fp_in,
  input  [SCALE_W-1:0] scale,
  input  [QBW-1:0] zp,
  output reg [COUNT*QBW-1:0] q_out
);

  integer i;
  integer q_tmp;
  integer q_max;
  reg [FP_W-1:0] fp_word;
  real val;
  real scale_real;
  real div_val;

  function real fp32_to_real;
    input [31:0] bits;
    integer sign;
    integer exp_raw;
    integer frac;
    real mant;
    begin
      sign = bits[31] ? -1 : 1;
      exp_raw = bits[30:23];
      frac = bits[22:0];

      if (exp_raw == 0 && frac == 0) begin
        fp32_to_real = 0.0;
      end else if (exp_raw == 0) begin
        mant = frac / 8388608.0;
        fp32_to_real = sign * mant * (2.0 ** (-126));
      end else if (exp_raw == 255) begin
        if (frac == 0)
          fp32_to_real = sign * 3.4028234663852886e38;
        else
          fp32_to_real = 0.0;
      end else begin
        mant = 1.0 + (frac / 8388608.0);
        fp32_to_real = sign * mant * (2.0 ** (exp_raw - 127));
      end
    end
  endfunction

  function integer round_to_int;
    input real x;
    integer base;
    real frac;
    begin
      base = $rtoi(x);

      if (x >= 0.0) begin
        frac = x - base;

        if (frac > 0.5)
          round_to_int = base + 1;
        else if (frac < 0.5)
          round_to_int = base;
        else if (base[0])
          round_to_int = base + 1;
        else
          round_to_int = base;
      end else begin
        frac = base - x;

        if (frac > 0.5)
          round_to_int = base - 1;
        else if (frac < 0.5)
          round_to_int = base;
        else if (base[0])
          round_to_int = base - 1;
        else
          round_to_int = base;
      end
    end
  endfunction

  always @* begin
    q_out = {COUNT*QBW{1'b0}};
    q_max = (1 << QBW) - 1;

    scale_real = scale / (2.0 ** SCALE_Q);
    if (scale_real == 0.0)
      scale_real = 1.0 / (2.0 ** SCALE_Q);

    for (i = 0; i < COUNT; i = i + 1) begin
      fp_word = fp_in[(COUNT-1-i)*FP_W +: FP_W];
      val = fp32_to_real(fp_word);
      div_val = val / scale_real;

      if ((div_val + zp) < 0.0)
        q_tmp = 0;
      else if ((div_val + zp) > q_max)
        q_tmp = q_max;
      else begin
        q_tmp = round_to_int(div_val) + zp;

        if (q_tmp < 0)
          q_tmp = 0;
        else if (q_tmp > q_max)
          q_tmp = q_max;
      end

      q_out[i*QBW +: QBW] = q_tmp[QBW-1:0];
    end
  end

endmodule