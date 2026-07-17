`timescale 1ns/1ps

module fp_add_comb (
    input  wire [31:0] a,
    input  wire [31:0] b,
    output wire [31:0] y
);

  real ar;
  real br;
  real yr;

  reg [31:0] result;

  always @* begin
    ar = $bitstoshortreal(a);
    br = $bitstoshortreal(b);
    yr = ar + br;
    result = $shortrealtobits(yr);
  end

  assign y = result;

endmodule