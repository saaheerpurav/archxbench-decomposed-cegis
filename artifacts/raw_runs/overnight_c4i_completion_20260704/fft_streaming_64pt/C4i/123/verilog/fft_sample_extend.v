`timescale 1ns/1ps

module fft_sample_extend #(
    parameter DATA_W = 16,
    parameter OUT_W  = 20
) (
    input  signed [DATA_W-1:0] real_in,
    input  signed [DATA_W-1:0] imag_in,
    output signed [OUT_W-1:0]  real_out,
    output signed [OUT_W-1:0]  imag_out
);

    assign real_out = {{(OUT_W-DATA_W){real_in[DATA_W-1]}}, real_in};
    assign imag_out = {{(OUT_W-DATA_W){imag_in[DATA_W-1]}}, imag_in};

endmodule