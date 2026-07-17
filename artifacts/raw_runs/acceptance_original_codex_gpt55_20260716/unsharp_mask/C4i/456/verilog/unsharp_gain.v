`timescale 1ns/1ps

module unsharp_gain #(
    parameter PIXEL_W = 8,
    parameter GAIN_W = 8
) (
    input  signed [PIXEL_W:0]        diff,
    input         [GAIN_W-1:0]       gain,
    output signed [PIXEL_W+GAIN_W:0] scaled
);

  wire signed [GAIN_W:0] gain_s;
  wire signed [PIXEL_W+GAIN_W+1:0] product;

  assign gain_s  = $signed({1'b0, gain});
  assign product = diff * gain_s;
  assign scaled  = product >>> (GAIN_W-1);

endmodule