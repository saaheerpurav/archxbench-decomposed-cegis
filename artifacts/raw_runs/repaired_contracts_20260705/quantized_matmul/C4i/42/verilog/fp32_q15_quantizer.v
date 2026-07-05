`timescale 1ns/1ps

module fp32_q15_quantizer #(
  parameter ROWS = 8,
  parameter COLS = 64,
  parameter FP_W = 32,
  parameter QBW = 8,
  parameter SCALE_W = 16,
  parameter SCALE_Q = 15
)(
  input  [ROWS*COLS*FP_W-1:0] fp_in,
  input  [SCALE_W-1:0] scale,
  input  [QBW-1:0] zp,
  output reg [ROWS*COLS*QBW-1:0] q_out
);

  integer idx;
  integer exp_i;
  integer shift_amt;
  integer max_q;
  integer q_int;
  integer limit_pos;

  reg [31:0] fp_bits;
  reg sign_bit;
  reg [7:0] exp_bits;
  reg [22:0] frac_bits;
  reg [23:0] mant;

  reg [63:0] num;
  reg [63:0] den;
  reg [63:0] quot;
  reg [63:0] rem_val;
  reg [63:0] mag;
  reg [63:0] scale_ext;

  always @(*) begin
    q_out = {(ROWS*COLS*QBW){1'b0}};
    max_q = (1 << QBW) - 1;
    scale_ext = {{(64-SCALE_W){1'b0}}, scale};

    for (idx = 0; idx < ROWS*COLS; idx = idx + 1) begin
      fp_bits  = fp_in[((ROWS*COLS-1-idx)*FP_W) +: FP_W];
      sign_bit = fp_bits[31];
      exp_bits = fp_bits[30:23];
      frac_bits = fp_bits[22:0];

      q_int = zp;
      mag = 0;

      if ((scale != 0) && (exp_bits != 8'hff)) begin
        if (exp_bits == 8'h00) begin
          mant = {1'b0, frac_bits};
          exp_i = -126;
        end else begin
          mant = {1'b1, frac_bits};
          exp_i = exp_bits;
          exp_i = exp_i - 127;
        end

        if (mant != 0) begin
          shift_amt = exp_i + SCALE_Q - 23;

          if (shift_amt >= 0) begin
            if (shift_amt > 31) begin
              mag = 64'h7fffffffffffffff;
            end else begin
              num = {40'b0, mant} << shift_amt;
              quot = num / scale_ext;
              rem_val = num - (quot * scale_ext);
              mag = quot;
              if ((rem_val << 1) >= scale_ext)
                mag = quot + 1;
            end
          end else begin
            if ((0 - shift_amt) > 31) begin
              mag = 0;
            end else begin
              num = {40'b0, mant};
              den = scale_ext << (0 - shift_amt);
              quot = num / den;
              rem_val = num - (quot * den);
              mag = quot;
              if ((rem_val << 1) >= den)
                mag = quot + 1;
            end
          end

          if (sign_bit) begin
            if (mag >= {56'b0, zp})
              q_int = 0;
            else
              q_int = zp - mag[31:0];
          end else begin
            limit_pos = max_q - zp;
            if (mag >= limit_pos)
              q_int = max_q;
            else
              q_int = zp + mag[31:0];
          end
        end
      end

      if (q_int < 0)
        q_int = 0;
      else if (q_int > max_q)
        q_int = max_q;

      q_out[idx*QBW +: QBW] = q_int[QBW-1:0];
    end
  end

endmodule