`timescale 1ns/1ps

module harris_sobel #(
    parameter PIXEL_W = 8,
    parameter GRAD_W = 16
) (
    input [PIXEL_W-1:0] p00, input [PIXEL_W-1:0] p01, input [PIXEL_W-1:0] p02,
    input [PIXEL_W-1:0] p10, input [PIXEL_W-1:0] p11, input [PIXEL_W-1:0] p12,
    input [PIXEL_W-1:0] p20, input [PIXEL_W-1:0] p21, input [PIXEL_W-1:0] p22,
    output signed [GRAD_W-1:0] gx,
    output signed [GRAD_W-1:0] gy
);

    function [PIXEL_W-1:0] clean_pixel;
        input [PIXEL_W-1:0] pix;
        begin
            if (^pix === 1'bx)
                clean_pixel = {PIXEL_W{1'b0}};
            else
                clean_pixel = pix;
        end
    endfunction

    wire signed [GRAD_W-1:0] s00 = {{(GRAD_W-PIXEL_W){1'b0}}, clean_pixel(p00)};
    wire signed [GRAD_W-1:0] s01 = {{(GRAD_W-PIXEL_W){1'b0}}, clean_pixel(p01)};
    wire signed [GRAD_W-1:0] s02 = {{(GRAD_W-PIXEL_W){1'b0}}, clean_pixel(p02)};
    wire signed [GRAD_W-1:0] s10 = {{(GRAD_W-PIXEL_W){1'b0}}, clean_pixel(p10)};
    wire signed [GRAD_W-1:0] s12 = {{(GRAD_W-PIXEL_W){1'b0}}, clean_pixel(p12)};
    wire signed [GRAD_W-1:0] s20 = {{(GRAD_W-PIXEL_W){1'b0}}, clean_pixel(p20)};
    wire signed [GRAD_W-1:0] s21 = {{(GRAD_W-PIXEL_W){1'b0}}, clean_pixel(p21)};
    wire signed [GRAD_W-1:0] s22 = {{(GRAD_W-PIXEL_W){1'b0}}, clean_pixel(p22)};

    assign gx = -s00 + s02 - (s10 <<< 1) + (s12 <<< 1) - s20 + s22;
    assign gy = -s00 - (s01 <<< 1) - s02 + s20 + (s21 <<< 1) + s22;

endmodule