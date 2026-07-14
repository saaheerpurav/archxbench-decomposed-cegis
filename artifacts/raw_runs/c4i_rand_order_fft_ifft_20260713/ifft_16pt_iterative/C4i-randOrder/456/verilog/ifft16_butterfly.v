`timescale 1ns/1ps

module ifft16_butterfly #(
    parameter DATA_W  = 16,
    parameter COEFF_W = 16
) (
    input  signed [DATA_W-1:0]  a_real,
    input  signed [DATA_W-1:0]  a_imag,
    input  signed [DATA_W-1:0]  b_real,
    input  signed [DATA_W-1:0]  b_imag,
    input  signed [COEFF_W-1:0] tw_cos,
    input  signed [COEFF_W-1:0] tw_sin,
    output signed [DATA_W-1:0]  y0_real,
    output signed [DATA_W-1:0]  y0_imag,
    output signed [DATA_W-1:0]  y1_real,
    output signed [DATA_W-1:0]  y1_imag
);

    wire signed [DATA_W-1:0] t_real;
    wire signed [DATA_W-1:0] t_imag;

    ifft16_complex_mult #(
        .DATA_W(DATA_W),
        .COEFF_W(COEFF_W)
    ) u_complex_mult (
        .a_real(b_real),
        .a_imag(b_imag),
        .tw_cos(tw_cos),
        .tw_sin(tw_sin),
        .y_real(t_real),
        .y_imag(t_imag)
    );

    assign y0_real = a_real + t_real;
    assign y0_imag = a_imag + t_imag;
    assign y1_real = a_real - t_real;
    assign y1_imag = a_imag - t_imag;

endmodule