`timescale 1ns/1ps

module fp32_math_pkg (
    input  wire [31:0] passthrough_in,
    output wire [31:0] passthrough_out
);
  assign passthrough_out = passthrough_in;

  function [31:0] fp32_mul;
    input [31:0] a;
    input [31:0] b;
    reg sign;
    reg [7:0] ea, eb;
    reg [23:0] ma, mb;
    reg [47:0] prod;
    reg signed [10:0] exp;
    reg [24:0] mant_round;
    reg guard, round_bit, sticky;
    begin
      sign = a[31] ^ b[31];
      ea = a[30:23];
      eb = b[30:23];

      if ((a[30:0] == 31'd0) || (b[30:0] == 31'd0)) begin
        fp32_mul = {sign, 31'd0};
      end else begin
        ma = (ea == 0) ? {1'b0, a[22:0]} : {1'b1, a[22:0]};
        mb = (eb == 0) ? {1'b0, b[22:0]} : {1'b1, b[22:0]};

        exp = (ea == 0 ? -126 : ea - 127) + (eb == 0 ? -126 : eb - 127);
        prod = ma * mb;

        if (prod[47]) begin
          mant_round = prod[47:23];
          guard = prod[22];
          round_bit = prod[21];
          sticky = |prod[20:0];
          exp = exp + 1;
        end else begin
          mant_round = prod[46:22];
          guard = prod[21];
          round_bit = prod[20];
          sticky = |prod[19:0];
        end

        if (guard && (round_bit || sticky || mant_round[0]))
          mant_round = mant_round + 1'b1;

        if (mant_round[24]) begin
          mant_round = mant_round >> 1;
          exp = exp + 1;
        end

        if (exp > 127)
          fp32_mul = {sign, 8'hfe, 23'h7fffff};
        else if (exp < -126)
          fp32_mul = {sign, 31'd0};
        else
          fp32_mul = {sign, exp[7:0] + 8'd127, mant_round[22:0]};
      end
    end
  endfunction

  function [31:0] fp32_add;
    input [31:0] a;
    input [31:0] b;
    reg sa, sb, sr;
    reg [7:0] ea, eb;
    reg signed [10:0] er;
    reg [27:0] ma, mb, mr;
    reg [27:0] shifted;
    integer shift;
    begin
      sa = a[31];
      sb = b[31];
      ea = a[30:23];
      eb = b[30:23];

      if (a[30:0] == 31'd0) begin
        fp32_add = b;
      end else if (b[30:0] == 31'd0) begin
        fp32_add = a;
      end else begin
        ma = {1'b1, a[22:0], 4'b0000};
        mb = {1'b1, b[22:0], 4'b0000};

        if (ea >= eb) begin
          er = ea - 127;
          shift = ea - eb;
          shifted = (shift >= 28) ? 28'd0 : (mb >> shift);
          ma = ma;
          mb = shifted;
          sr = sa;
        end else begin
          er = eb - 127;
          shift = eb - ea;
          shifted = (shift >= 28) ? 28'd0 : (ma >> shift);
          ma = shifted;
          mb = mb;
          sr = sb;
        end

        if (sa == sb) begin
          mr = ma + mb;
          sr = sa;
          if (mr[27]) begin
            mr = mr >> 1;
            er = er + 1;
          end
        end else begin
          if (ma >= mb) begin
            mr = ma - mb;
            sr = sa;
          end else begin
            mr = mb - ma;
            sr = sb;
          end

          while (mr[26] == 1'b0 && mr != 0 && er > -126) begin
            mr = mr << 1;
            er = er - 1;
          end
        end

        if (mr == 0)
          fp32_add = 32'd0;
        else if (er > 127)
          fp32_add = {sr, 8'hfe, 23'h7fffff};
        else if (er < -126)
          fp32_add = {sr, 31'd0};
        else
          fp32_add = {sr, er[7:0] + 8'd127, mr[25:3]};
      end
    end
  endfunction

endmodule