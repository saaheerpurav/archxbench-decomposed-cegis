`timescale 1ns/1ps

module gaussian3x3_blur #(
    parameter PIXEL_W = 8
) (
    input  [PIXEL_W-1:0] p00,
    input  [PIXEL_W-1:0] p01,
    input  [PIXEL_W-1:0] p02,
    input  [PIXEL_W-1:0] p10,
    input  [PIXEL_W-1:0] p11,
    input  [PIXEL_W-1:0] p12,
    input  [PIXEL_W-1:0] p20,
    input  [PIXEL_W-1:0] p21,
    input  [PIXEL_W-1:0] p22,
    output [PIXEL_W-1:0] blurred
);

    wire [PIXEL_W+4:0] sum;
    wire [PIXEL_W+4:0] rounded_sum;

    assign sum =
        {5'b00000, p00} +
        {4'b0000,  p01, 1'b0} +
        {5'b00000, p02} +
        {4'b0000,  p10, 1'b0} +
        {3'b000,   p11, 2'b00} +
        {4'b0000,  p12, 1'b0} +
        {5'b00000, p20} +
        {4'b0000,  p21, 1'b0} +
        {5'b00000, p22};

    assign rounded_sum = sum + {{(PIXEL_W+1){1'b0}}, 4'b1000};

    assign blurred = rounded_sum[PIXEL_W+3:4];

endmodule