`timescale 1ns/1ps

module gaussian_blur_3x3 #(
    parameter PIXEL_W = 8
) (
    input [PIXEL_W-1:0] p00,
    input [PIXEL_W-1:0] p01,
    input [PIXEL_W-1:0] p02,
    input [PIXEL_W-1:0] p10,
    input [PIXEL_W-1:0] p11,
    input [PIXEL_W-1:0] p12,
    input [PIXEL_W-1:0] p20,
    input [PIXEL_W-1:0] p21,
    input [PIXEL_W-1:0] p22,
    output [PIXEL_W-1:0] blur_pixel
);

    localparam SUM_W = PIXEL_W + 4;

    wire [SUM_W-1:0] weighted_sum;

    assign weighted_sum =
        p00 + (p01 << 1) + p02 +
        (p10 << 1) + (p11 << 2) + (p12 << 1) +
        p20 + (p21 << 1) + p22;

    assign blur_pixel = weighted_sum[SUM_W-1:4] != 0
                      ? {PIXEL_W{1'b1}}
                      : weighted_sum[PIXEL_W+3:4];

endmodule