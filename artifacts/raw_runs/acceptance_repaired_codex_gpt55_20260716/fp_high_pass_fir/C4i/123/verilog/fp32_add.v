`timescale 1ns/1ps

module fp32_add (
    input  wire [31:0] a,
    input  wire [31:0] b,
    output reg  [31:0] y
);

  shortreal ar;
  shortreal br;
  shortreal yr;

  always @* begin
    ar = $bitstoshortreal(a);
    br = $bitstoshortreal(b);
    yr = ar + br;
    y = $shortrealtobits(yr);
  end

endmodule