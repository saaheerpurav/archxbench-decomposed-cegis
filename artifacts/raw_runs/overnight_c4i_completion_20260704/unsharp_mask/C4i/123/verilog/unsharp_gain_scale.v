`timescale 1ns/1ps

module unsharp_gain_scale #(
    parameter GAIN_W = 8,
    parameter DIFF_W = 10,
    parameter PROD_W = DIFF_W + GAIN_W
) (
    input  signed [DIFF_W-1:0] diff,
    input         [GAIN_W-1:0] gain,
    output signed [PROD_W-1:0] scaled
);

    wire signed [PROD_W-1:0] diff_ext;
    wire signed [PROD_W-1:0] gain_ext;

    assign diff_ext = {{(PROD_W-DIFF_W){diff[DIFF_W-1]}}, diff};
    assign gain_ext = {{(PROD_W-GAIN_W){1'b0}}, gain};

    assign scaled = diff_ext * gain_ext;

endmodule