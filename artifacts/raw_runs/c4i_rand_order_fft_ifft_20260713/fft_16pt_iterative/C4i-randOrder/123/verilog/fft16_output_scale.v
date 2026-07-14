`timescale 1ns/1ps

module fft16_output_scale #(
    parameter IN_W = 16,
    parameter SHIFT = 4
) (
    input  signed [IN_W-1:0] value_in,
    input                    ifft_mode,
    output signed [IN_W-1:0] value_out
);

    assign value_out = ifft_mode ? (value_in >>> SHIFT) : value_in;

endmodule