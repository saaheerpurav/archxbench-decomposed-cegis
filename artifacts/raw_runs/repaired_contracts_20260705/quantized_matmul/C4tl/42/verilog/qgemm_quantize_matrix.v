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
  output reg signed [ELEMS*QBW-1:0] centered_q
);

  integer idx;
  reg [FP_W-1:0] fp_bits;
  integer q_int;
  integer q_min;
  integer q_max;
  real fp_val;
  real scale_val;
  real div_val;

  function real fp32_to_real;
    input [31:0] bits;
    integer sign;
    integer exp;
    integer mant;
    real frac;
    real val;
    integer e;
    begin
      sign = bits[31];
      exp = bits[30:23];
      mant = bits[22:0];

      if (exp == 0 && mant == 0) begin
        val = 0.0;
      end else if (exp == 0) begin
        frac = mant / 8388608.0;
        val = frac;
        for (e = -126; e < 0; e = e + 1)
          val = val / 2.0;
      end else if (exp == 255) begin
        val = 0.0;
      end else begin
        frac = 1.0 + (mant / 8388608.0);
        val = frac;
        if (exp >= 127) begin
          for (e = 0; e < exp - 127; e = e + 1)
            val = val * 2.0;
        end else begin
          for (e = 0; e < 127 - exp; e = e + 1)
            val = val / 2.0;
        end
      end

      fp32_to_real = sign ? -val : val;
    end
  endfunction

  function integer round_real_to_int;
    input real x;
    begin
      if (x >= 0.0)
        round_real_to_int = $rtoi(x + 0.5);
      else
        round_real_to_int = -$rtoi((-x) + 0.5);
    end
  endfunction

  always @* begin
    q_min = 0;
    q_max = (1 << QBW) - 1;
    scale_val = scale / (1.0 * (1 << SCALE_Q));

    for (idx = 0; idx < ELEMS; idx = idx + 1) begin
      fp_bits = fp_in[(ELEMS-1-idx)*FP_W +: FP_W];
      fp_val = fp32_to_real(fp_bits);

      if (scale == 0)
        q_int = zp;
      else begin
        div_val = fp_val / scale_val;
        q_int = round_real_to_int(div_val) + zp;
      end

      if (q_int < q_min)
        q_int = q_min;
      if (q_int > q_max)
        q_int = q_max;

      centered_q[idx*QBW +: QBW] = $signed(q_int - zp);
    end
  end

endmodule