`timescale 1ns/1ps

module gaussian3x3_blur #(
    parameter PIXEL_W = 8,
    parameter SUM_W = PIXEL_W + 8
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
    output [SUM_W-1:0] blur_sum,
    output [PIXEL_W-1:0] blur_px
);
    assign blur_sum =
        p00 + (p01 << 1) + p02 +
        (p10 << 1) + (p11 << 2) + (p12 << 1) +
        p20 + (p21 << 1) + p22;

    assign blur_px = blur_sum >> 4;
endmodule