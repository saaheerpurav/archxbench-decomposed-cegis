`timescale 1ns/1ps

module fft64_complex_mult #(
    parameter DATA_W = 20
) (
    input signed [DATA_W-1:0] a_real,
    input signed [DATA_W-1:0] a_imag,
    input signed [DATA_W-1:0] b_real,
    input signed [DATA_W-1:0] b_imag,
    output signed [DATA_W-1:0] p_real,
    output signed [DATA_W-1:0] p_imag
);
    wire signed [(2*DATA_W)-1:0] rr = a_real * b_real;
    wire signed [(2*DATA_W)-1:0] ii = a_imag * b_imag;
    wire signed [(2*DATA_W)-1:0] ri = a_real * b_imag;
    wire signed [(2*DATA_W)-1:0] ir = a_imag * b_real;

    wire signed [(2*DATA_W):0] real_full = rr - ii;
    wire signed [(2*DATA_W):0] imag_full = ri + ir;

    assign p_real = real_full >>> 15;
    assign p_imag = imag_full >>> 15;
endmodule