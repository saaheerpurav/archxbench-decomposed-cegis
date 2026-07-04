`timescale 1ns/1ps

module harris_sobel_3x3 #(
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
    output signed [GRAD_W-1:0] grad_x,
    output signed [GRAD_W-1:0] grad_y
);

    wire signed [GRAD_W-1:0] w00 = $signed({1'b0, p00});
    wire signed [GRAD_W-1:0] w01 = $signed({1'b0, p01});
    wire signed [GRAD_W-1:0] w02 = $signed({1'b0, p02});
    wire signed [GRAD_W-1:0] w10 = $signed({1'b0, p10});
    wire signed [GRAD_W-1:0] w12 = $signed({1'b0, p12});
    wire signed [GRAD_W-1:0] w20 = $signed({1'b0, p20});
    wire signed [GRAD_W-1:0] w21 = $signed({1'b0, p21});
    wire signed [GRAD_W-1:0] w22 = $signed({1'b0, p22});

    assign grad_x = -w00 + w02 - (w10 <<< 1) + (w12 <<< 1) - w20 + w22;
    assign grad_y = -w00 - (w01 <<< 1) - w02 + w20 + (w21 <<< 1) + w22;

endmodule