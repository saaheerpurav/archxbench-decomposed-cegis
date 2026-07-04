`timescale 1ns/1ps

module unsharp_window3x3 #(
    parameter IMG_WIDTH = 256,
    parameter IMG_HEIGHT = 256,
    parameter PIXEL_W = 8
) (
    input [31:0] idx,
    input [PIXEL_W-1:0] p00_in,
    input [PIXEL_W-1:0] p01_in,
    input [PIXEL_W-1:0] p02_in,
    input [PIXEL_W-1:0] p10_in,
    input [PIXEL_W-1:0] p11_in,
    input [PIXEL_W-1:0] p12_in,
    input [PIXEL_W-1:0] p20_in,
    input [PIXEL_W-1:0] p21_in,
    input [PIXEL_W-1:0] p22_in,
    output [PIXEL_W-1:0] p00,
    output [PIXEL_W-1:0] p01,
    output [PIXEL_W-1:0] p02,
    output [PIXEL_W-1:0] p10,
    output [PIXEL_W-1:0] p11,
    output [PIXEL_W-1:0] p12,
    output [PIXEL_W-1:0] p20,
    output [PIXEL_W-1:0] p21,
    output [PIXEL_W-1:0] p22
);
    assign p00 = p00_in;
    assign p01 = p01_in;
    assign p02 = p02_in;
    assign p10 = p10_in;
    assign p11 = p11_in;
    assign p12 = p12_in;
    assign p20 = p20_in;
    assign p21 = p21_in;
    assign p22 = p22_in;
endmodule