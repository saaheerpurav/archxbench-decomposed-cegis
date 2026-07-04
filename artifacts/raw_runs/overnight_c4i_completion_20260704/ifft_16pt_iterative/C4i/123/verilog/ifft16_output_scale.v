`timescale 1ns/1ps

module ifft16_output_scale #(
    parameter WORK_W = 20,
    parameter OUT_W  = 16,
    parameter SHIFT  = 4
) (
    input  signed [WORK_W-1:0] in_real,
    input  signed [WORK_W-1:0] in_imag,
    output signed [OUT_W-1:0]  out_real,
    output signed [OUT_W-1:0]  out_imag
);

    wire signed [WORK_W-1:0] scaled_real;
    wire signed [WORK_W-1:0] scaled_imag;

    assign scaled_real = in_real >>> SHIFT;
    assign scaled_imag = in_imag >>> SHIFT;

    assign out_real = scaled_real[OUT_W-1:0];
    assign out_imag = scaled_imag[OUT_W-1:0];

endmodule