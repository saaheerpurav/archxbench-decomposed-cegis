`timescale 1ns/1ps

module fp32_mul (
    input wire [31:0] a,
    input wire [31:0] b,
    output reg [31:0] y
);
  reg sign;
  reg [7:0] ea, eb;
  reg [23:0] ma, mb;
  reg [47:0] product;
  reg [24:0] mant;
  integer exp;

  always @* begin
    sign = a[31] ^ b[31];
    ea = a[30:23];
    eb = b[30:23];

    ma = (ea == 0) ? {1'b0, a[22:0]} : {1'b1, a[22:0]};
    mb = (eb == 0) ? {1'b0, b[22:0]} : {1'b1, b[22:0]};

    if ((a[30:0] == 31'd0) || (b[30:0] == 31'd0)) begin
      y = 32'h00000000;
    end else begin
      product = ma * mb;
      exp = (ea == 0 ? 1 : ea) + (eb == 0 ? 1 : eb) - 127;

      if (product[47]) begin
        mant = product[47:23] + product[22];
        exp = exp + 1;
      end else begin
        mant = product[46:22] + product[21];
      end

      if (mant[24]) begin
        mant = mant >> 1;
        exp = exp + 1;
      end

      if (exp >= 255)
        y = {sign, 8'hfe, 23'h7fffff};
      else if (exp <= 0)
        y = 32'h00000000;
      else
        y = {sign, exp[7:0], mant[22:0]};
    end
  end
endmodule