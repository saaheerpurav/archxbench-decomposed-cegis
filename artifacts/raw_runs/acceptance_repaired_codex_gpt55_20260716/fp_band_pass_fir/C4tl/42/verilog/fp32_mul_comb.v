`timescale 1ns/1ps

module fp32_mul_comb (
    input wire [31:0] a,
    input wire [31:0] b,
    output wire [31:0] y
);

  function real pow2;
    input integer e;
    integer j;
    real v;
    begin
      v = 1.0;
      if (e >= 0)
        for (j = 0; j < e; j = j + 1) v = v * 2.0;
      else
        for (j = 0; j < -e; j = j + 1) v = v / 2.0;
      pow2 = v;
    end
  endfunction

  function real fp32_to_real;
    input [31:0] f;
    integer exp;
    integer mant;
    real m;
    begin
      if (f[30:23] == 8'd0 && f[22:0] == 23'd0)
        fp32_to_real = 0.0;
      else begin
        exp = f[30:23] - 127;
        mant = f[22:0];
        m = (f[30:23] == 8'd0) ? (mant / 8388608.0) : (1.0 + mant / 8388608.0);
        fp32_to_real = f[31] ? -m * pow2(exp) : m * pow2(exp);
      end
    end
  endfunction

  function [31:0] real_to_fp32;
    input real r;
    reg sign;
    real v, scaled;
    integer exp, mant;
    begin
      if (r == 0.0) begin
        real_to_fp32 = 32'h00000000;
      end else begin
        sign = (r < 0.0);
        v = sign ? -r : r;
        exp = 0;
        while (v >= 2.0) begin v = v / 2.0; exp = exp + 1; end
        while (v < 1.0) begin v = v * 2.0; exp = exp - 1; end
        scaled = (v - 1.0) * 8388608.0;
        mant = scaled + 0.5;
        if (mant >= 8388608) begin mant = 0; exp = exp + 1; end
        if (exp + 127 <= 0)
          real_to_fp32 = 32'h00000000;
        else if (exp + 127 >= 255)
          real_to_fp32 = {sign, 8'hfe, 23'h7fffff};
        else
          real_to_fp32 = {sign, exp[7:0] + 8'd127, mant[22:0]};
      end
    end
  endfunction

  assign y = real_to_fp32(fp32_to_real(a) * fp32_to_real(b));

endmodule