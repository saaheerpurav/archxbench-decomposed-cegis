`timescale 1ns/1ps

module fft16_output_scale #(
    parameter IN_W = 16,
    parameter GAIN_W = 4
) (
    input mode,
    input signed [IN_W-1:0] in_real,
    input signed [IN_W-1:0] in_imag,
    output signed [IN_W-1:0] out_real,
    output signed [IN_W-1:0] out_imag
);

  assign out_real = mode ? (in_real >>> GAIN_W) : in_real;
  assign out_imag = mode ? (in_imag >>> GAIN_W) : in_imag;

endmodule