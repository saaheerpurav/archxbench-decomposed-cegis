`timescale 1ns/1ps

module fft_complex_addsub #(
    parameter W = 20
) (
    input  signed [W-1:0] a_real,
    input  signed [W-1:0] a_imag,
    input  signed [W-1:0] b_real,
    input  signed [W-1:0] b_imag,
    input                 subtract,
    output signed [W-1:0] y_real,
    output signed [W-1:0] y_imag
);

    wire signed [W:0] a_real_ext = {a_real[W-1], a_real};
    wire signed [W:0] a_imag_ext = {a_imag[W-1], a_imag};
    wire signed [W:0] b_real_ext = {b_real[W-1], b_real};
    wire signed [W:0] b_imag_ext = {b_imag[W-1], b_imag};

    wire signed [W:0] real_sum = subtract
                                ? (a_real_ext - b_real_ext)
                                : (a_real_ext + b_real_ext);

    wire signed [W:0] imag_sum = subtract
                                ? (a_imag_ext - b_imag_ext)
                                : (a_imag_ext + b_imag_ext);

    assign y_real = real_sum[W-1:0];
    assign y_imag = imag_sum[W-1:0];

endmodule