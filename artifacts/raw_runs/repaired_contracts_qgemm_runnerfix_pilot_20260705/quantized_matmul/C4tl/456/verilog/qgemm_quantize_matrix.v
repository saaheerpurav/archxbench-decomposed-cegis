`timescale 1ns/1ps

module qgemm_quantize_matrix #(
  parameter ELEM_COUNT = 512,
  parameter FP_W = 32,
  parameter QBW = 8,
  parameter SCALE_W = 16,
  parameter SCALE_Q = 15
)(
  input  wire [ELEM_COUNT*FP_W-1:0] fp_in,
  input  wire [SCALE_W-1:0] scale,
  input  wire [QBW-1:0] zp,
  output reg  [ELEM_COUNT*QBW-1:0] q_out
);

  integer idx;
  integer q_int;
  real scale_real;
  real fp_real;
  reg [FP_W-1:0] fp_bits;

  function real fp32_to_real;
    input [31:0] bits;
    integer sign;
    integer exp;
    integer frac;
    real mant;
    real val;
    begin
      sign = bits[31] ? -1 : 1;
      exp = bits[30:23];
      frac = bits[22:0];

      if (exp == 255) begin
        val = 0.0;
      end else if (exp == 0) begin
        mant = frac / 8388608.0;
        val = sign * mant * (2.0 ** (-126));
      end else begin
        mant = 1.0 + (frac / 8388608.0);
        val = sign * mant * (2.0 ** (exp - 127));
      end
      fp32_to_real = val;
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

  always @* begin
    scale_real = scale / (2.0 ** SCALE_Q);
    q_out = {ELEM_COUNT*QBW{1'b0}};

    for (idx = 0; idx < ELEM_COUNT; idx = idx + 1) begin
      fp_bits = fp_in[(ELEM_COUNT-1-idx)*FP_W +: FP_W];
      fp_real = fp32_to_real(fp_bits);

      if (scale_real == 0.0)
        q_int = $signed(zp);
      else
        q_int = round_real_to_int(fp_real / scale_real) + $signed(zp);

      q_out[(ELEM_COUNT-1-idx)*QBW +: QBW] = q_int[QBW-1:0];
    end
  end

endmodule