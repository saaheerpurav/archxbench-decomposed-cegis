`timescale 1ns/1ps

module fft16_ifft_scale #(
    parameter DATA_W = 16,
    parameter LOGN = 4
) (
    input mode,
    input signed [DATA_W-1:0] in_real,
    input signed [DATA_W-1:0] in_imag,
    output signed [DATA_W-1:0] out_real,
    output signed [DATA_W-1:0] out_imag
);

    assign out_real = mode ? (in_real >>> LOGN) : in_real;
    assign out_imag = mode ? (in_imag >>> LOGN) : in_imag;

endmodule