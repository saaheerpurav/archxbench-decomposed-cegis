`timescale 1ns/1ps

module qgemm_quantize_matrix #(
  parameter ROWS = 8,
  parameter COLS = 64,
  parameter FP_W = 32,
  parameter QBW = 8,
  parameter SCALE_W = 16,
  parameter SCALE_Q = 15
)(
  input  [ROWS*COLS*FP_W-1:0] fp_matrix,
  input  [SCALE_W-1:0] scale,
  input  [QBW-1:0] zp,
  output reg [ROWS*COLS*QBW-1:0] q_matrix
);

  function real fp32_to_real;
    input [31:0] bits;
    reg sign;
    reg [7:0] exp;
    reg [22:0] frac;
    real mant;
    integer e;
    begin
      sign = bits[31];
      exp  = bits[30:23];
      frac = bits[22:0];

      if (exp == 8'h00) begin
        if (frac == 23'd0) begin
          mant = 0.0;
          e = 0;
        end else begin
          mant = frac / 8388608.0;
          e = -126;
        end
      end else if (exp == 8'hff) begin
        mant = 0.0;
        e = 0;
      end else begin
        mant = 1.0 + (frac / 8388608.0);
        e = exp - 127;
      end

      fp32_to_real = mant * (2.0 ** e);
      if (sign)
        fp32_to_real = -fp32_to_real;
    end
  endfunction

  function integer round_ties_to_even;
    input real value;
    real abs_value;
    real frac;
    integer floor_value;
    integer rounded_abs;
    begin
      if (value < 0.0)
        abs_value = -value;
      else
        abs_value = value;

      floor_value = $rtoi(abs_value);
      frac = abs_value - floor_value;

      if (frac > 0.500000000001) begin
        rounded_abs = floor_value + 1;
      end else if (frac < 0.499999999999) begin
        rounded_abs = floor_value;
      end else begin
        if (floor_value[0])
          rounded_abs = floor_value + 1;
        else
          rounded_abs = floor_value;
      end

      if (value < 0.0)
        round_ties_to_even = -rounded_abs;
      else
        round_ties_to_even = rounded_abs;
    end
  endfunction

  integer idx;
  integer q_int;
  real scale_real;
  real fp_real;
  reg [31:0] fp_bits;

  always @* begin
    q_matrix = {ROWS*COLS*QBW{1'b0}};
    scale_real = scale / (2.0 ** SCALE_Q);

    for (idx = 0; idx < ROWS*COLS; idx = idx + 1) begin
      fp_bits = fp_matrix[((ROWS*COLS-1-idx)*FP_W) +: FP_W];

      if (scale == {SCALE_W{1'b0}}) begin
        q_int = $signed(zp);
      end else begin
        fp_real = fp32_to_real(fp_bits);
        q_int = round_ties_to_even(fp_real / scale_real) + $signed(zp);
      end

      q_matrix[idx*QBW +: QBW] = q_int[QBW-1:0];
    end
  end

endmodule