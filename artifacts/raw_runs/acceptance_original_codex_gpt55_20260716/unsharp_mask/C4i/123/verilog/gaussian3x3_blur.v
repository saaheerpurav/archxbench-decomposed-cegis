`timescale 1ns/1ps

module gaussian3x3_blur #(
    parameter PIXEL_W = 8,
    parameter SUM_W = PIXEL_W + 6
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

    wire [SUM_W-1:0] ep00 = {{(SUM_W-PIXEL_W){1'b0}}, p00};
    wire [SUM_W-1:0] ep01 = {{(SUM_W-PIXEL_W){1'b0}}, p01};
    wire [SUM_W-1:0] ep02 = {{(SUM_W-PIXEL_W){1'b0}}, p02};
    wire [SUM_W-1:0] ep10 = {{(SUM_W-PIXEL_W){1'b0}}, p10};
    wire [SUM_W-1:0] ep11 = {{(SUM_W-PIXEL_W){1'b0}}, p11};
    wire [SUM_W-1:0] ep12 = {{(SUM_W-PIXEL_W){1'b0}}, p12};
    wire [SUM_W-1:0] ep20 = {{(SUM_W-PIXEL_W){1'b0}}, p20};
    wire [SUM_W-1:0] ep21 = {{(SUM_W-PIXEL_W){1'b0}}, p21};
    wire [SUM_W-1:0] ep22 = {{(SUM_W-PIXEL_W){1'b0}}, p22};

    wire [SUM_W-1:0] sum;

    assign sum =
        ep00 + (ep01 << 1) + ep02 +
        (ep10 << 1) + (ep11 << 2) + (ep12 << 1) +
        ep20 + (ep21 << 1) + ep22;

    assign blurred = sum[PIXEL_W+3:4];

endmodule