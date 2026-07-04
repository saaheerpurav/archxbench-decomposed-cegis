`timescale 1ns/1ps

module qgemm_quantize_tile #(
  parameter ROWS = 8,
  parameter COLS = 64,
  parameter FP_W = 32,
  parameter QBW = 8,
  parameter ACC_W = 32,
  parameter SCALE_W = 16,
  parameter SCALE_Q = 15
)(
  input  [ROWS*COLS*FP_W-1:0] fp_in,
  input  [SCALE_W-1:0] scale,
  input  [QBW-1:0] zp,
  output reg [ROWS*COLS*ACC_W-1:0] q_centered
);

  integer idx;
  reg [FP_W-1:0] fp_word;

  function signed [ACC_W-1:0] fp32_to_qcenter;
    input [31:0] fp;
    input [SCALE_W-1:0] sc;
    input [QBW-1:0] zpoint;

    reg sign;
    reg [7:0] exp;
    reg [22:0] frac;
    reg [23:0] mant;
    integer e;
    integer sh;

    reg [255:0] num;
    reg [255:0] den;
    reg [255:0] quo;
    reg [255:0] rem;
    reg [255:0] mag_rounded;

    reg signed [255:0] signed_unbiased;
    reg signed [255:0] signed_biased;
    reg signed [255:0] signed_clamped;
    reg signed [255:0] centered;
    reg [255:0] qmax;

    begin
      sign = fp[31];
      exp  = fp[30:23];
      frac = fp[22:0];

      qmax = (256'd1 << QBW) - 1;

      if (sc == 0) begin
        fp32_to_qcenter = {ACC_W{1'b0}};
      end else if (exp == 8'hff) begin
        if (sign)
          signed_clamped = 0;
        else
          signed_clamped = qmax;
        centered = signed_clamped - {{(256-QBW){1'b0}}, zpoint};
        fp32_to_qcenter = centered[ACC_W-1:0];
      end else if (exp == 0 && frac == 0) begin
        fp32_to_qcenter = {ACC_W{1'b0}};
      end else begin
        if (exp == 0) begin
          mant = {1'b0, frac};
          e = -126;
        end else begin
          mant = {1'b1, frac};
          e = exp - 127;
        end

        sh = e + SCALE_Q - 23;

        if (sh >= 0) begin
          num = {232'd0, mant} << sh;
          den = {{(256-SCALE_W){1'b0}}, sc};
        end else begin
          num = {232'd0, mant};
          den = {{(256-SCALE_W){1'b0}}, sc} << (-sh);
        end

        quo = num / den;
        rem = num - (quo * den);

        if ((rem << 1) >= den)
          mag_rounded = quo + 1;
        else
          mag_rounded = quo;

        if (sign)
          signed_unbiased = -$signed(mag_rounded);
        else
          signed_unbiased = $signed(mag_rounded);

        signed_biased = signed_unbiased + {{(256-QBW){1'b0}}, zpoint};

        if (signed_biased < 0)
          signed_clamped = 0;
        else if (signed_biased > $signed(qmax))
          signed_clamped = qmax;
        else
          signed_clamped = signed_biased;

        centered = signed_clamped - {{(256-QBW){1'b0}}, zpoint};
        fp32_to_qcenter = centered[ACC_W-1:0];
      end
    end
  endfunction

  always @* begin
    q_centered = {(ROWS*COLS*ACC_W){1'b0}};

    for (idx = 0; idx < ROWS*COLS; idx = idx + 1) begin
      fp_word = fp_in[(ROWS*COLS*FP_W-1) - idx*FP_W -: FP_W];
      q_centered[idx*ACC_W +: ACC_W] = fp32_to_qcenter(fp_word, scale, zp);
    end
  end

endmodule