`timescale 1ns/1ps

module harris_sobel3x3 #(
    parameter PIXEL_W = 8,
    parameter GRAD_W = 16
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
    output signed [GRAD_W-1:0] gx,
    output signed [GRAD_W-1:0] gy
);

    wire signed [GRAD_W-1:0] sp00 = {{(GRAD_W-PIXEL_W){1'b0}}, p00};
    wire signed [GRAD_W-1:0] sp01 = {{(GRAD_W-PIXEL_W){1'b0}}, p01};
    wire signed [GRAD_W-1:0] sp02 = {{(GRAD_W-PIXEL_W){1'b0}}, p02};
    wire signed [GRAD_W-1:0] sp10 = {{(GRAD_W-PIXEL_W){1'b0}}, p10};
    wire signed [GRAD_W-1:0] sp12 = {{(GRAD_W-PIXEL_W){1'b0}}, p12};
    wire signed [GRAD_W-1:0] sp20 = {{(GRAD_W-PIXEL_W){1'b0}}, p20};
    wire signed [GRAD_W-1:0] sp21 = {{(GRAD_W-PIXEL_W){1'b0}}, p21};
    wire signed [GRAD_W-1:0] sp22 = {{(GRAD_W-PIXEL_W){1'b0}}, p22};

    assign gx = -sp00 + sp02 - (sp10 <<< 1) + (sp12 <<< 1) - sp20 + sp22;
    assign gy = -sp00 - (sp01 <<< 1) - sp02 + sp20 + (sp21 <<< 1) + sp22;

endmodule