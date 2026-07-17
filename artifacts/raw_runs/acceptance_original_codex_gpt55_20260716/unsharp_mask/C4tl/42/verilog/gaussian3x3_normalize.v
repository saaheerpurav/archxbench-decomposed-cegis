`timescale 1ns/1ps

module gaussian3x3_normalize #(
    parameter PIXEL_W = 8,
    parameter SUM_W = PIXEL_W + 4
) (
    input [SUM_W-1:0] sum,
    output [PIXEL_W-1:0] blur
);
    assign blur = sum[PIXEL_W+3:4];
endmodule