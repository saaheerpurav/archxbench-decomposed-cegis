`timescale 1ns/1ps

module pixel_difference #(
    parameter PIXEL_W = 8,
    parameter DIFF_W = PIXEL_W + 12
) (
    input [PIXEL_W-1:0] orig,
    input [PIXEL_W-1:0] blur,
    output signed [DIFF_W-1:0] diff
);
    assign diff = $signed({1'b0, orig}) - $signed({1'b0, blur});
endmodule