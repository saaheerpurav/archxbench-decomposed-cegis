`timescale 1ns/1ps

module unsharp_reconstruct #(
    parameter PIXEL_W = 8,
    parameter GAIN_W = 8
) (
    input  [PIXEL_W-1:0] original,
    input  signed [PIXEL_W+GAIN_W:0] scaled,
    output [PIXEL_W-1:0] pixel_out
);

  wire signed [PIXEL_W+GAIN_W+1:0] result;

  assign result = $signed({1'b0, original}) + scaled;

  assign pixel_out =
      (result < 0) ? {PIXEL_W{1'b0}} :
      (result > ((1 << PIXEL_W) - 1)) ? {PIXEL_W{1'b1}} :
      result[PIXEL_W-1:0];

endmodule