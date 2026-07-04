`timescale 1ns/1ps

module fft64_output_order #(
    parameter DATA_W = 20,
    parameter POINTS = 64
) (
    input signed [DATA_W-1:0] real_in,
    input signed [DATA_W-1:0] imag_in,
    input valid_in,
    input last_in,
    output signed [DATA_W-1:0] real_out,
    output signed [DATA_W-1:0] imag_out,
    output valid_out,
    output last_out
);
    assign real_out = real_in;
    assign imag_out = imag_in;
    assign valid_out = valid_in;
    assign last_out = last_in;
endmodule