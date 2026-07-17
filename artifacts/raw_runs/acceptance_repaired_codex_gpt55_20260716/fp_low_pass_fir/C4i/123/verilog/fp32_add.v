`timescale 1ns/1ps

module fp32_add (
    input  wire [31:0] a,
    input  wire [31:0] b,
    output reg  [31:0] y
);
  reg        sa, sb, sy;
  reg [7:0]  ea, eb;
  reg [7:0]  exp_a, exp_b;
  reg [23:0] sig_a, sig_b;
  reg [27:0] ext_a, ext_b;
  reg [27:0] al_a, al_b;
  reg [28:0] sum;
  reg [27:0] mag;
  reg [8:0]  exp;
  reg [24:0] rounded;
  reg [23:0] sig_out;
  reg        inc;
  integer    shift;

  function [27:0] shr_sticky;
    input [27:0] v;
    input integer sh;
    reg sticky;
    begin
      if (sh <= 0) begin
        shr_sticky = v;
      end else if (sh >= 28) begin
        shr_sticky = (v != 28'd0) ? 28'd1 : 28'd0;
      end else begin
        sticky = |(v & ((28'd1 << sh) - 28'd1));
        shr_sticky = (v >> sh);
        shr_sticky[0] = shr_sticky[0] | sticky;
      end
    end
  endfunction

  always @* begin
    sa = a[31];
    sb = b[31];
    ea = a[30:23];
    eb = b[30:23];

    exp_a = (ea == 8'd0) ? 8'd1 : ea;
    exp_b = (eb == 8'd0) ? 8'd1 : eb;

    sig_a = (ea == 8'd0) ? {1'b0, a[22:0]} : {1'b1, a[22:0]};
    sig_b = (eb == 8'd0) ? {1'b0, b[22:0]} : {1'b1, b[22:0]};

    ext_a = {1'b0, sig_a, 3'b000};
    ext_b = {1'b0, sig_b, 3'b000};

    if (a[30:0] == 31'd0) begin
      y = b;
    end else if (b[30:0] == 31'd0) begin
      y = a;
    end else begin
      if (exp_a >= exp_b) begin
        exp = exp_a;
        shift = exp_a - exp_b;
        al_a = ext_a;
        al_b = shr_sticky(ext_b, shift);
      end else begin
        exp = exp_b;
        shift = exp_b - exp_a;
        al_a = shr_sticky(ext_a, shift);
        al_b = ext_b;
      end

      if (sa == sb) begin
        sum = {1'b0, al_a} + {1'b0, al_b};
        sy = sa;

        if (sum[27]) begin
          mag = sum[28:1];
          mag[0] = mag[0] | sum[0];
          exp = exp + 9'd1;
        end else begin
          mag = sum[27:0];
        end
      end else begin
        if (al_a >= al_b) begin
          mag = al_a - al_b;
          sy = sa;
        end else begin
          mag = al_b - al_a;
          sy = sb;
        end

        while (mag != 28'd0 && mag[26] == 1'b0 && exp > 9'd1) begin
          mag = mag << 1;
          exp = exp - 9'd1;
        end
      end

      if (mag == 28'd0) begin
        y = 32'h00000000;
      end else begin
        while (exp <= 9'd0 && mag != 28'd0) begin
          mag = shr_sticky(mag, 1);
          exp = exp + 9'd1;
        end

        inc = mag[2] & (mag[1] | mag[0] | mag[3]);
        rounded = {1'b0, mag[26:3]} + inc;

        if (rounded[24]) begin
          sig_out = rounded[24:1];
          exp = exp + 9'd1;
        end else begin
          sig_out = rounded[23:0];
        end

        if (exp >= 9'd255) begin
          y = {sy, 8'hfe, 23'h7fffff};
        end else if (exp == 9'd1 && sig_out[23] == 1'b0) begin
          y = {sy, 8'd0, sig_out[22:0]};
        end else begin
          y = {sy, exp[7:0], sig_out[22:0]};
        end
      end
    end
  end
endmodule