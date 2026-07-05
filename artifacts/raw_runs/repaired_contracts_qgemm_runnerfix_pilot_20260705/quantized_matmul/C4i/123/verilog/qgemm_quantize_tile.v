`timescale 1ns/1ps

module qgemm_quantize_tile #(
  parameter ELEMS = 512,
  parameter FP_W = 32,
  parameter QBW = 8,
  parameter SCALE_W = 16,
  parameter SCALE_Q = 15
)(
  input  [ELEMS*FP_W-1:0] fp_in,
  input  [SCALE_W-1:0] scale,
  input  [QBW-1:0] zp,
  output reg [ELEMS*QBW-1:0] q_out
);

  integer i;
  reg [31:0] fp_bits;
  integer q_int;
  real fp_val;
  real sc_val;

  function real fp32_to_real;
    input [31:0] bits;
    reg sign;
    reg [7:0] exp;
    reg [22:0] frac;
    real mant;
    integer e;
    integer j;
    begin
      sign = bits[31];
      exp  = bits[30:23];
      frac = bits[22:0];

      if (exp == 8'h00) begin
        mant = 0.0;
        for (j = 0; j < 23; j = j + 1)
          if (frac[j])
            mant = mant + (2.0 ** (j - 149));
        fp32_to_real = sign ? -mant : mant;
      end else if (exp == 8'hff) begin
        fp32_to_real = 0.0;
      end else begin
        mant = 1.0;
        for (j = 0; j < 23; j = j + 1)
          if (frac[j])
            mant = mant + (2.0 ** (j - 23));

        e = exp - 127;
        fp32_to_real = sign ? -(mant * (2.0 ** e)) : (mant * (2.0 ** e));
      end
    end
  endfunction

  function integer round_ties_to_even;
    input real x;
    integer whole;
    real frac;
    begin
      if (x >= 0.0) begin
        whole = $rtoi(x);
        frac = x - whole;

        if (frac > 0.5)
          round_ties_to_even = whole + 1;
        else if (frac < 0.5)
          round_ties_to_even = whole;
        else
          round_ties_to_even = whole[0] ? whole + 1 : whole;
      end else begin
        whole = $rtoi(-x);
        frac = (-x) - whole;

        if (frac > 0.5)
          round_ties_to_even = -(whole + 1);
        else if (frac < 0.5)
          round_ties_to_even = -whole;
        else
          round_ties_to_even = whole[0] ? -(whole + 1) : -whole;
      end
    end
  endfunction

  always @* begin
    sc_val = $itor(scale) / (2.0 ** SCALE_Q);
    q_out = {ELEMS*QBW{1'b0}};

    for (i = 0; i < ELEMS; i = i + 1) begin
      fp_bits = fp_in[(ELEMS-1-i)*FP_W +: FP_W];
      fp_val = fp32_to_real(fp_bits);

      if (sc_val == 0.0)
        q_int = $signed(zp);
      else
        q_int = round_ties_to_even(fp_val / sc_val) + $signed(zp);

      q_out[i*QBW +: QBW] = q_int[QBW-1:0];
    end
  end

endmodule