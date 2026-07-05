`timescale 1ns/1ps

module qgemm_quantize_matrix #(
  parameter ELEMS = 512,
  parameter FP_W = 32,
  parameter QBW = 8,
  parameter SCALE_W = 16,
  parameter SCALE_Q = 15
)(
  input  [ELEMS*FP_W-1:0] fp_in,
  input  [SCALE_W-1:0] scale,
  input  [QBW-1:0] zp,
  output reg signed [ELEMS*QBW-1:0] q_out
);

  integer i;
  integer q_int;
  real scale_real;
  real fp_real;
  reg [FP_W-1:0] fp_bits;

  function real fp32_to_real;
    input [31:0] bits;
    reg sign;
    integer exp;
    integer frac;
    real mant;
    real val;
    begin
      sign = bits[31];
      exp = bits[30:23];
      frac = bits[22:0];

      if (exp == 0 && frac == 0) begin
        val = 0.0;
      end else if (exp == 0) begin
        mant = frac / 8388608.0;
        val = mant * (2.0 ** (-126));
      end else if (exp == 255) begin
        val = 0.0;
      end else begin
        mant = 1.0 + (frac / 8388608.0);
        val = mant * (2.0 ** (exp - 127));
      end

      fp32_to_real = sign ? -val : val;
    end
  endfunction

  function integer round_even;
    input real x;
    integer floor_i;
    integer abs_floor;
    real frac;
    begin
      floor_i = $floor(x);
      frac = x - floor_i;

      if (frac > 0.5) begin
        round_even = floor_i + 1;
      end else if (frac < 0.5) begin
        round_even = floor_i;
      end else begin
        abs_floor = (floor_i < 0) ? -floor_i : floor_i;
        round_even = ((abs_floor % 2) == 0) ? floor_i : floor_i + 1;
      end
    end
  endfunction

  always @* begin
    scale_real = scale / (2.0 ** SCALE_Q);
    q_out = {ELEMS*QBW{1'b0}};

    for (i = 0; i < ELEMS; i = i + 1) begin
      fp_bits = fp_in[(ELEMS-1-i)*FP_W +: FP_W];
      fp_real = fp32_to_real(fp_bits);

      if (scale_real == 0.0)
        q_int = $signed(zp);
      else
        q_int = round_even(fp_real / scale_real) + $signed(zp);

      q_out[i*QBW +: QBW] = q_int[QBW-1:0];
    end
  end

endmodule