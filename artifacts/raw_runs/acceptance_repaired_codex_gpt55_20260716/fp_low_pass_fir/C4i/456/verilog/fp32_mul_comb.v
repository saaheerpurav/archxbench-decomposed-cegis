`timescale 1ns/1ps

module fp32_mul_comb (
    input  wire [31:0] a,
    input  wire [31:0] b,
    output reg  [31:0] y
);
  reg        sign;
  reg [7:0]  ea, eb;
  reg [23:0] ma, mb;
  reg [47:0] prod;

  integer exp_a;
  integer exp_b;
  integer exp_field;

  reg [22:0] frac;
  reg        guard;
  reg        roundb;
  reg        sticky;
  reg [24:0] mant_round;

  always @* begin
    ea = a[30:23];
    eb = b[30:23];
    sign = a[31] ^ b[31];

    if ((a[30:0] == 31'd0) || (b[30:0] == 31'd0)) begin
      y = 32'h00000000;
    end else begin
      ma = (ea == 8'd0) ? {1'b0, a[22:0]} : {1'b1, a[22:0]};
      mb = (eb == 8'd0) ? {1'b0, b[22:0]} : {1'b1, b[22:0]};

      exp_a = ea;
      if (ea == 8'd0)
        exp_a = -126;
      else
        exp_a = exp_a - 127;

      exp_b = eb;
      if (eb == 8'd0)
        exp_b = -126;
      else
        exp_b = exp_b - 127;

      exp_field = exp_a + exp_b + 127;
      prod = ma * mb;

      if (prod[47]) begin
        frac = prod[46:24];
        guard = prod[23];
        roundb = prod[22];
        sticky = |prod[21:0];
        exp_field = exp_field + 1;
      end else begin
        frac = prod[45:23];
        guard = prod[22];
        roundb = prod[21];
        sticky = |prod[20:0];
      end

      mant_round = {1'b0, 1'b1, frac} +
                   ((guard && (roundb || sticky || frac[0])) ? 25'd1 : 25'd0);

      if (mant_round[24]) begin
        mant_round = mant_round >> 1;
        exp_field = exp_field + 1;
      end

      if (exp_field >= 255)
        y = {sign, 8'hfe, 23'h7fffff};
      else if (exp_field <= 0)
        y = 32'h00000000;
      else
        y = {sign, exp_field[7:0], mant_round[22:0]};
    end
  end
endmodule