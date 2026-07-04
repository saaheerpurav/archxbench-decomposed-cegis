`timescale 1ns/1ps

module fft_radix2_butterfly #(
    parameter DATA_W = 20
) (
    input  signed [DATA_W-1:0] a_re,
    input  signed [DATA_W-1:0] a_im,
    input  signed [DATA_W-1:0] b_re,
    input  signed [DATA_W-1:0] b_im,
    output signed [DATA_W-1:0] sum_re,
    output signed [DATA_W-1:0] sum_im,
    output signed [DATA_W-1:0] diff_re,
    output signed [DATA_W-1:0] diff_im
);

    assign sum_re  = a_re + b_re;
    assign sum_im  = a_im + b_im;
    assign diff_re = a_re - b_re;
    assign diff_im = a_im - b_im;

endmodule