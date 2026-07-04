`timescale 1ns/1ps

module qgemm_quantizer #(
  parameter VLEN = 8,
  parameter K = 64,
  parameter FP_W = 32,
  parameter QBW = 8,
  parameter SCALE_W = 16,
  parameter SCALE_Q = 15,
  parameter IS_B = 0
)(
  input  [VLEN*K*FP_W-1:0] fp_in,
  input  [SCALE_W-1:0]     scale,
  input  [QBW-1:0]         zp,
  output reg [VLEN*K*QBW-1:0] q_out
);

  integer idx;
  integer packed_idx;
  integer q_int;
  integer zp_int;
  integer q_min;
  integer q_max;

  real fp_val;
  real scale_real;
  real scaled_val;

  reg [FP_W-1:0] fp_bits;

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

  function real fp32_to_real;
    input [31:0] bits;
    integer sign_bit;
    integer exp_raw;
    integer mantissa;
    real fraction;
    real value;
    begin
      sign_bit = bits[31];
      exp_raw = bits[30:23];
      mantissa = bits[22:0];

      if (exp_raw == 0 && mantissa == 0) begin
        value = 0.0;
      end else if (exp_raw == 0) begin
        fraction = mantissa / 8388608.0;
        value = fraction * pow2(-126);
      end else if (exp_raw == 255) begin
        value = 0.0;
      end else begin
        fraction = 1.0 + (mantissa / 8388608.0);
        value = fraction * pow2(exp_raw - 127);
      end

      if (sign_bit)
        fp32_to_real = -value;
      else
        fp32_to_real = value;
    end
  endfunction

  function integer round_to_int;
    input real value;
    begin
      if (value >= 0.0)
        round_to_int = $rtoi(value + 0.5);
      else
        round_to_int = $rtoi(value - 0.5);
    end
  endfunction

  always @* begin
    q_out = {VLEN*K*QBW{1'b0}};

    zp_int = zp;
    q_min = 0;
    q_max = (1 << QBW) - 1;
    scale_real = scale / pow2(SCALE_Q);

    for (idx = 0; idx < VLEN*K; idx = idx + 1) begin
      packed_idx = (VLEN*K - 1 - idx) * FP_W;
      fp_bits = fp_in[packed_idx +: FP_W];
      fp_val = fp32_to_real(fp_bits);

      if (scale == 0) begin
        q_int = zp_int;
      end else begin
        scaled_val = fp_val / scale_real;
        q_int = round_to_int(scaled_val) + zp_int;
      end

      if (q_int < q_min)
        q_int = q_min;
      else if (q_int > q_max)
        q_int = q_max;

      q_out[idx*QBW +: QBW] = q_int[QBW-1:0];
    end
  end

endmodule