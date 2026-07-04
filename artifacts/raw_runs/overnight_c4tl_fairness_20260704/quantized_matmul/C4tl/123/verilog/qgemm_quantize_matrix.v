`timescale 1ns/1ps

module qgemm_quantize_matrix #(
  parameter ROWS = 8,
  parameter COLS = 64,
  parameter FP_W = 32,
  parameter QBW = 8,
  parameter SCALE_W = 16,
  parameter SCALE_Q = 15
)(
  input [ROWS*COLS*FP_W-1:0] fp_matrix,
  input [SCALE_W-1:0] scale,
  input [QBW-1:0] zp,
  output reg [ROWS*COLS*QBW-1:0] centered_matrix
);

  integer idx;
  integer qval;
  integer centered;
  reg [FP_W-1:0] fp_word;
  real fp_real;
  real scale_real;

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

      if (sign)
        fp32_to_real = -val;
      else
        fp32_to_real = val;
    end
  endfunction

  function integer round_real_to_int;
    input real value;
    begin
      if (value >= 0.0)
        round_real_to_int = $rtoi(value + 0.5);
      else
        round_real_to_int = $rtoi(value - 0.5);
    end
  endfunction

  always @* begin
    centered_matrix = {(ROWS*COLS*QBW){1'b0}};
    scale_real = scale / (2.0 ** SCALE_Q);

    for (idx = 0; idx < ROWS*COLS; idx = idx + 1) begin
      fp_word = fp_matrix[((ROWS*COLS-1-idx)*FP_W) +: FP_W];
      fp_real = fp32_to_real(fp_word);

      if (scale == 0)
        qval = zp;
      else
        qval = round_real_to_int(fp_real / scale_real) + zp;

      if (qval < 0)
        qval = 0;
      else if (qval > ((1 << QBW) - 1))
        qval = (1 << QBW) - 1;

      centered = qval - zp;
      centered_matrix[idx*QBW +: QBW] = centered[QBW-1:0];
    end
  end

endmodule