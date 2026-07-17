`timescale 1ns/1ps

module gaussian3x3_norm #(
    parameter PIXEL_W = 8,
    parameter ACC_W = PIXEL_W + 8
) (
    input [ACC_W-1:0] sum,
    output [PIXEL_W-1:0] blur
);
    assign blur = sum[PIXEL_W+3:4];
endmodule