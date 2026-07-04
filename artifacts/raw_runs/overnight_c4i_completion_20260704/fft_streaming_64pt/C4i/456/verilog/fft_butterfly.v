`timescale 1ns/1ps

module fft_butterfly #(
    parameter DATA_W = 20
) (
    input  signed [DATA_W-1:0] a_real,
    input  signed [DATA_W-1:0] a_imag,
    input  signed [DATA_W-1:0] b_real,
    input  signed [DATA_W-1:0] b_imag,
    output signed [DATA_W-1:0] sum_real,
    output signed [DATA_W-1:0] sum_imag,
    output signed [DATA_W-1:0] diff_real,
    output signed [DATA_W-1:0] diff_imag
);

    assign sum_real  = a_real + b_real;
    assign sum_imag  = a_imag + b_imag;
    assign diff_real = a_real - b_real;
    assign diff_imag = a_imag - b_imag;

endmodule