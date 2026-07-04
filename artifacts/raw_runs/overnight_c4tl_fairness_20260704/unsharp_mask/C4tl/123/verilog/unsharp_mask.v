`timescale 1ns/1ps

module unsharp_mask #(
    parameter IMG_WIDTH = 256,
    parameter IMG_HEIGHT = 256,
    parameter PIXEL_W = 8,
    parameter GAIN_W = 8
) (
    input clk,
    input rst,
    input [PIXEL_W-1:0] pixel_in,
    input valid_in,
    input [GAIN_W-1:0] gain,
    output [PIXEL_W-1:0] pixel_out,
    output valid_out
);

    wire [PIXEL_W-1:0] blur_pixel;
    wire signed [PIXEL_W:0] high_freq;
    wire signed [PIXEL_W+GAIN_W:0] scaled_high_freq;
    wire [PIXEL_W-1:0] sharpened_pixel;

    gaussian_blur_3x3 #(
        .PIXEL_W(PIXEL_W)
    ) u_blur (
        .p00({PIXEL_W{1'b0}}),
        .p01({PIXEL_W{1'b0}}),
        .p02({PIXEL_W{1'b0}}),
        .p10({PIXEL_W{1'b0}}),
        .p11(pixel_in),
        .p12({PIXEL_W{1'b0}}),
        .p20({PIXEL_W{1'b0}}),
        .p21({PIXEL_W{1'b0}}),
        .p22({PIXEL_W{1'b0}}),
        .blur_pixel(blur_pixel)
    );

    pointwise_subtract #(
        .PIXEL_W(PIXEL_W)
    ) u_subtract (
        .original_pixel(pixel_in),
        .blur_pixel(blur_pixel),
        .high_freq(high_freq)
    );

    pointwise_gain #(
        .PIXEL_W(PIXEL_W),
        .GAIN_W(GAIN_W)
    ) u_gain (
        .high_freq(high_freq),
        .gain(gain),
        .scaled_high_freq(scaled_high_freq)
    );

    pointwise_reconstruct #(
        .PIXEL_W(PIXEL_W),
        .GAIN_W(GAIN_W)
    ) u_reconstruct (
        .original_pixel(pixel_in),
        .scaled_high_freq(scaled_high_freq),
        .pixel_out(sharpened_pixel)
    );

    assign pixel_out = sharpened_pixel;
    assign valid_out = valid_in & ~rst;

endmodule