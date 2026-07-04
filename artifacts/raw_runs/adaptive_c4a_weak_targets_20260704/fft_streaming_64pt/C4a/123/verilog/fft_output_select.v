`timescale 1ns/1ps

module fft_output_select #(
    parameter W = 20
) (
    input  signed [W-1:0] direct_real,
    input  signed [W-1:0] direct_imag,
    input  signed [W-1:0] alt_real,
    input  signed [W-1:0] alt_imag,
    input                 select_alt,
    output signed [W-1:0] real_out,
    output signed [W-1:0] imag_out
);

    assign real_out = select_alt ? alt_real : direct_real;
    assign imag_out = select_alt ? alt_imag : direct_imag;

endmodule