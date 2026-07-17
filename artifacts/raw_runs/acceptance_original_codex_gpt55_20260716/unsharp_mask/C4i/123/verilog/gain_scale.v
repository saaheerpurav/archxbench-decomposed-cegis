`timescale 1ns/1ps

module gain_scale #(
    parameter DIFF_W = 10,
    parameter GAIN_W = 8,
    parameter PROD_W = DIFF_W + GAIN_W + 1
) (
    input  signed [DIFF_W-1:0] diff,
    input         [GAIN_W-1:0] gain,
    output signed [PROD_W-1:0] scaled
);

    wire signed [GAIN_W:0] gain_ext;

    assign gain_ext = {1'b0, gain};
    assign scaled = diff * gain_ext;

endmodule