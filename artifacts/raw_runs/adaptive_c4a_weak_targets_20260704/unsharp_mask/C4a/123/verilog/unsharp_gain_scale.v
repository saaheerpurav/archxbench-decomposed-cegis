`timescale 1ns/1ps

module unsharp_gain_scale #(
    parameter GAIN_W = 8,
    parameter DIFF_W = 10,
    parameter SCALE_W = 19
) (
    input  signed [DIFF_W-1:0]  diff,
    input         [GAIN_W-1:0]  gain,
    output signed [SCALE_W-1:0] scaled
);

    wire signed [GAIN_W:0] gain_signed;
    wire signed [DIFF_W+GAIN_W:0] product;

    assign gain_signed = {1'b0, gain};
    assign product = diff * gain_signed;
    assign scaled = product;

endmodule