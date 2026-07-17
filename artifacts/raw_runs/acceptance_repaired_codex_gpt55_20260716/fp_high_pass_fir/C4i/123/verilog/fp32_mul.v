`timescale 1ns/1ps

module fp32_mul (
    input  wire [31:0] a,
    input  wire [31:0] b,
    output reg  [31:0] y
);

  reg sign;
  reg [7:0] exp_a, exp_b;
  reg [22:0] frac_a, frac_b;
  reg [23:0] sig_a, sig_b;
  reg signed [12:0] e_a, e_b;
  reg [47:0] prod;

  integer msb;
  integer i;
  integer sh;
  integer rsh;

  reg signed [12:0] exp_unb;
  reg [47:0] shifted_prod;
  reg [24:0] mant_ext;
  reg [23:0] mant24;
  reg guard_bit;
  reg sticky_bit;
  reg round_inc;

  reg [47:0] sticky_mask;

  always @* begin
    sign   = a[31] ^ b[31];
    exp_a  = a[30:23];
    exp_b  = b[30:23];
    frac_a = a[22:0];
    frac_b = b[22:0];

    y = 32'h00000000;

    if ((exp_a == 8'hff && frac_a != 23'd0) ||
        (exp_b == 8'hff && frac_b != 23'd0)) begin
      y = 32'h7fc00000;
    end else if ((exp_a == 8'hff && (exp_b == 8'd0 && frac_b == 23'd0)) ||
                 (exp_b == 8'hff && (exp_a == 8'd0 && frac_a == 23'd0))) begin
      y = 32'h7fc00000;
    end else if (exp_a == 8'hff || exp_b == 8'hff) begin
      y = {sign, 8'hff, 23'd0};
    end else if ((exp_a == 8'd0 && frac_a == 23'd0) ||
                 (exp_b == 8'd0 && frac_b == 23'd0)) begin
      y = {sign, 31'd0};
    end else begin
      sig_a = (exp_a == 8'd0) ? {1'b0, frac_a} : {1'b1, frac_a};
      sig_b = (exp_b == 8'd0) ? {1'b0, frac_b} : {1'b1, frac_b};

      e_a = (exp_a == 8'd0) ? -126 : ($signed({5'd0, exp_a}) - 127);
      e_b = (exp_b == 8'd0) ? -126 : ($signed({5'd0, exp_b}) - 127);

      prod = sig_a * sig_b;

      msb = 0;
      for (i = 47; i >= 0; i = i - 1) begin
        if (prod[i] && msb == 0)
          msb = i;
      end

      exp_unb = e_a + e_b + msb - 46;

      if (exp_unb > 127) begin
        y = {sign, 8'hff, 23'd0};
      end else if (exp_unb >= -126) begin
        sh = msb - 23;

        if (sh > 0) begin
          mant24 = prod >> sh;
          guard_bit = prod[sh - 1];

          sticky_bit = 1'b0;
          for (i = 0; i < sh - 1; i = i + 1)
            sticky_bit = sticky_bit | prod[i];
        end else begin
          mant24 = prod << (-sh);
          guard_bit = 1'b0;
          sticky_bit = 1'b0;
        end

        round_inc = guard_bit & (sticky_bit | mant24[0]);
        mant_ext = {1'b0, mant24} + round_inc;

        if (mant_ext[24]) begin
          exp_unb = exp_unb + 1;
          mant24 = mant_ext[24:1];
        end else begin
          mant24 = mant_ext[23:0];
        end

        if (exp_unb > 127)
          y = {sign, 8'hff, 23'd0};
        else
          y = {sign, exp_unb[7:0] + 8'd127, mant24[22:0]};
      end else begin
        rsh = (-149) - (e_a + e_b - 46);

        if (rsh >= 48) begin
          mant24 = 24'd0;
          guard_bit = 1'b0;
          sticky_bit = |prod;
        end else if (rsh > 0) begin
          mant24 = prod >> rsh;
          guard_bit = prod[rsh - 1];

          sticky_bit = 1'b0;
          for (i = 0; i < rsh - 1; i = i + 1)
            sticky_bit = sticky_bit | prod[i];
        end else begin
          mant24 = prod << (-rsh);
          guard_bit = 1'b0;
          sticky_bit = 1'b0;
        end

        round_inc = guard_bit & (sticky_bit | mant24[0]);
        mant_ext = {1'b0, mant24} + round_inc;

        if (mant_ext[24])
          y = {sign, 8'd1, 23'd0};
        else
          y = {sign, 8'd0, mant_ext[22:0]};
      end
    end
  end

endmodule