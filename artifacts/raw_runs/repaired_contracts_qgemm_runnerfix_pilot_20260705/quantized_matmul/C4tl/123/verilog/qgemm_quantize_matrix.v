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
  output reg [ELEMS*QBW-1:0] q_out
);

  integer i;
  reg [FP_W-1:0] fp_word;
  reg signed [31:0] q_word;

  function real fp32_to_real;
    input [31:0] bits;
    integer exp;
    integer mant;
    real frac;
    real val;
    begin
      if (bits[30:23] == 8'h00) begin
        mant = bits[22:0];
        frac = mant;
        val = frac * (2.0 ** (-149));
      end else if (bits[30:23] == 8'hff) begin
        val = 0.0;
      end else begin
        exp = bits[30:23] - 127;
        mant = bits[22:0];
        frac = 1.0 + (mant / 8388608.0);
        val = frac * (2.0 ** exp);
      end
      if (bits[31])
        fp32_to_real = -val;
      else
        fp32_to_real = val;
    end
  endfunction

  function signed [31:0] round_real_to_int;
    input real x;
    real ax;
    integer base;
    real frac;
    begin
      if (x >= 0.0) begin
        base = x;
        frac = x - base;
        if (frac >= 0.5)
          round_real_to_int = base + 1;
        else
          round_real_to_int = base;
      end else begin
        ax = -x;
        base = ax;
        frac = ax - base;
        if (frac >= 0.5)
          round_real_to_int = -(base + 1);
        else
          round_real_to_int = -base;
      end
    end
  endfunction

  function signed [31:0] quant_one;
    input [31:0] fp_bits;
    input [SCALE_W-1:0] sc;
    input [QBW-1:0] zero;
    real fval;
    real sval;
    reg signed [31:0] centered;
    begin
      fval = fp32_to_real(fp_bits);
      if (sc == 0)
        centered = 0;
      else begin
        sval = sc / (2.0 ** SCALE_Q);
        centered = round_real_to_int(fval / sval);
      end
      quant_one = centered + $signed(zero);
    end
  endfunction

  always @* begin
    q_out = {ELEMS*QBW{1'b0}};
    for (i = 0; i < ELEMS; i = i + 1) begin
      fp_word = fp_in[(ELEMS-1-i)*FP_W +: FP_W];
      q_word = quant_one(fp_word, scale, zp);
      q_out[i*QBW +: QBW] = q_word[QBW-1:0];
    end
  end

endmodule