`timescale 1ns/1ps

module qgemm_quantize_a #(
  parameter VLEN = 8,
  parameter K = 64,
  parameter FP_W = 32,
  parameter QBW = 8,
  parameter SCALE_W = 16,
  parameter SCALE_Q = 15
)(
  input  wire [VLEN*K*FP_W-1:0] A_fp,
  input  wire [SCALE_W-1:0] scale_A,
  input  wire [QBW-1:0] zp_A,
  output reg  [VLEN*K*QBW-1:0] A_q
);

  integer idx;
  reg [31:0] fp_bits;
  integer qval;

  function real fp32_to_real;
    input [31:0] bits;
    integer sign;
    integer exp;
    integer mant;
    real frac;
    begin
      sign = bits[31];
      exp = bits[30:23];
      mant = bits[22:0];

      if (exp == 0 && mant == 0) begin
        fp32_to_real = 0.0;
      end else if (exp == 0) begin
        frac = mant / 8388608.0;
        fp32_to_real = (sign ? -1.0 : 1.0) * frac * (2.0 ** (-126));
      end else begin
        frac = 1.0 + (mant / 8388608.0);
        fp32_to_real = (sign ? -1.0 : 1.0) * frac * (2.0 ** (exp - 127));
      end
    end
  endfunction

  function integer round_real_to_int;
    input real x;
    begin
      if (x >= 0.0)
        round_real_to_int = $rtoi(x + 0.5);
      else
        round_real_to_int = $rtoi(x - 0.5);
    end
  endfunction

  function integer quantize_fp32;
    input [31:0] bits;
    input [SCALE_W-1:0] scale_q;
    input [QBW-1:0] zp;
    real f;
    real scale;
    integer q;
    integer qmin;
    integer qmax;
    begin
      qmin = 0;
      qmax = (1 << QBW) - 1;
      scale = scale_q / (2.0 ** SCALE_Q);
      f = fp32_to_real(bits);

      if (scale_q == 0)
        q = zp;
      else
        q = round_real_to_int(f / scale) + zp;

      if (q < qmin)
        q = qmin;
      if (q > qmax)
        q = qmax;

      quantize_fp32 = q;
    end
  endfunction

  always @* begin
    A_q = {VLEN*K*QBW{1'b0}};

    for (idx = 0; idx < VLEN*K; idx = idx + 1) begin
      fp_bits = A_fp[(VLEN*K-1-idx)*FP_W +: FP_W];
      qval = quantize_fp32(fp_bits, scale_A, zp_A);
      A_q[idx*QBW +: QBW] = qval[QBW-1:0];
    end
  end

endmodule