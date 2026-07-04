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
    output [PIXEL_W-1:0] blur
);

    localparam SUM_W = PIXEL_W + 4;

    wire [SUM_W-1:0] p00_w = {{4{1'b0}}, p00};
    wire [SUM_W-1:0] p01_w = {{4{1'b0}}, p01};
    wire [SUM_W-1:0] p02_w = {{4{1'b0}}, p02};
    wire [SUM_W-1:0] p10_w = {{4{1'b0}}, p10};
    wire [SUM_W-1:0] p11_w = {{4{1'b0}}, p11};
    wire [SUM_W-1:0] p12_w = {{4{1'b0}}, p12};
    wire [SUM_W-1:0] p20_w = {{4{1'b0}}, p20};
    wire [SUM_W-1:0] p21_w = {{4{1'b0}}, p21};
    wire [SUM_W-1:0] p22_w = {{4{1'b0}}, p22};

    wire [SUM_W-1:0] sum;

    assign sum =
        p00_w + (p01_w << 1) + p02_w +
        (p10_w << 1) + (p11_w << 2) + (p12_w << 1) +
        p20_w + (p21_w << 1) + p22_w;

    assign blur = sum[SUM_W-1:4];

endmodule