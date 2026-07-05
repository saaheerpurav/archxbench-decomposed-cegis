`timescale 1ns/1ps

module qgemm_quantize_matrix #(
  parameter ELEMS = 512,
  parameter COUNT = ELEMS,
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
  integer qi;
  integer max_q;
  real val;
  real sc;

  function real fp32_to_real;
    input [31:0] bits;
    integer exp;
    integer frac;
    integer n;
    real mant;
    real pow2;
    begin
      exp = bits[30:23];
      frac = bits[22:0];

      if (exp == 255) begin
        fp32_to_real = 0.0;
      end else if (exp == 0) begin
        mant = frac;
        mant = mant / 8388608.0;
        pow2 = 1.0;
        for (n = 0; n < 126; n = n + 1)
          pow2 = pow2 / 2.0;
        fp32_to_real = mant * pow2;
        if (bits[31])
          fp32_to_real = -fp32_to_real;
      end else begin
        mant = 1.0 + (frac / 8388608.0);
        pow2 = 1.0;
        if (exp >= 127) begin
          for (n = 0; n < exp - 127; n = n + 1)
            pow2 = pow2 * 2.0;
        end else begin
          for (n = 0; n < 127 - exp; n = n + 1)
            pow2 = pow2 / 2.0;
        end
        fp32_to_real = mant * pow2;
        if (bits[31])
          fp32_to_real = -fp32_to_real;
      end
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

  always @(*) begin
    max_q = (1 << QBW) - 1;
    sc = scale;
    sc = sc / (1 << SCALE_Q);
    q_out = {COUNT*QBW{1'b0}};

    for (i = 0; i < COUNT; i = i + 1) begin
      val = fp32_to_real(fp_in[(COUNT-1-i)*FP_W +: FP_W]);

      if (scale == 0)
        qi = zp;
      else
        qi = round_real_to_int(val / sc) + zp;

      if (qi < 0)
        qi = 0;
      else if (qi > max_q)
        qi = max_q;

      q_out[i*QBW +: QBW] = qi[QBW-1:0];
    end
  end

endmodule