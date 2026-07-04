`timescale 1ns/1ps

module fft64_radix2_butterfly #(
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

    wire signed [DATA_W:0] a_real_ext = {a_real[DATA_W-1], a_real};
    wire signed [DATA_W:0] a_imag_ext = {a_imag[DATA_W-1], a_imag};
    wire signed [DATA_W:0] b_real_ext = {b_real[DATA_W-1], b_real};
    wire signed [DATA_W:0] b_imag_ext = {b_imag[DATA_W-1], b_imag};

    wire signed [DATA_W:0] sum_real_ext  = a_real_ext + b_real_ext;
    wire signed [DATA_W:0] sum_imag_ext  = a_imag_ext + b_imag_ext;
    wire signed [DATA_W:0] diff_real_ext = a_real_ext - b_real_ext;
    wire signed [DATA_W:0] diff_imag_ext = a_imag_ext - b_imag_ext;

    assign sum_real  = sum_real_ext[DATA_W-1:0];
    assign sum_imag  = sum_imag_ext[DATA_W-1:0];
    assign diff_real = diff_real_ext[DATA_W-1:0];
    assign diff_imag = diff_imag_ext[DATA_W-1:0];

endmodule