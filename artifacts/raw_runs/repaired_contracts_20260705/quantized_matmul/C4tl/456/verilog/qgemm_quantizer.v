`timescale 1ns/1ps

module qgemm_quantizer #(
  parameter COUNT = 512,
  parameter FP_W = 32,
  parameter SCALE_W = 16,
  parameter QBW = 8,
  parameter OUT_W = 32,
  parameter SCALE_Q = 15
)(
  input [COUNT*FP_W-1:0] fp_in,
  input [SCALE_W-1:0] scale,
  input [QBW-1:0] zp,
  output reg signed [COUNT*OUT_W-1:0] centered_out
);

  integer idx;
  reg [FP_W-1:0] bits;

  function signed [OUT_W-1:0] fp32_to_quant_centered;
    input [31:0] f;
    input [SCALE_W-1:0] sc;
    reg sign;
    reg [7:0] exp;
    reg [22:0] frac;
    reg [63:0] mant;
    reg [63:0] num;
    reg [63:0] den;
    reg [63:0] qabs;
    integer sh;
    begin
      sign = f[31];
      exp = f[30:23];
      frac = f[22:0];

      if (sc == 0 || exp == 0 || exp == 8'hff) begin
        fp32_to_quant_centered = {OUT_W{1'b0}};
      end else begin
        mant = {40'b0, 1'b1, frac};
        sh = exp - 135;

        if (sh >= 0) begin
          if (sh > 31)
            num = 64'h7fffffffffffffff;
          else
            num = mant << sh;
          den = sc;
        end else begin
          num = mant;
          if ((-sh) > 45)
            den = 64'h7fffffffffffffff;
          else
            den = ({48'b0, sc} << (-sh));
        end

        if (den == 0)
          qabs = 0;
        else
          qabs = (num + (den >> 1)) / den;

        if (sign)
          fp32_to_quant_centered = -$signed(qabs[OUT_W-1:0]);
        else
          fp32_to_quant_centered = $signed(qabs[OUT_W-1:0]);
      end
    end
  endfunction

  always @* begin
    for (idx = 0; idx < COUNT; idx = idx + 1) begin
      bits = fp_in[(COUNT-1-idx)*FP_W +: FP_W];
      centered_out[idx*OUT_W +: OUT_W] = fp32_to_quant_centered(bits, scale);
    end
  end

endmodule