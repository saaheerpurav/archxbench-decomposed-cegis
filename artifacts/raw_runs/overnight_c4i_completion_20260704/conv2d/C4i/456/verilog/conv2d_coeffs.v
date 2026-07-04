`timescale 1ns/1ps

module conv2d_coeffs #(
    parameter KERNEL_SIZE = 3
) (
    output [KERNEL_SIZE*KERNEL_SIZE*16-1:0] flat_coeffs
);

    assign flat_coeffs[0*16 +: 16] = 16'd1;
    assign flat_coeffs[1*16 +: 16] = 16'd2;
    assign flat_coeffs[2*16 +: 16] = 16'd1;

    assign flat_coeffs[3*16 +: 16] = 16'd2;
    assign flat_coeffs[4*16 +: 16] = 16'd4;
    assign flat_coeffs[5*16 +: 16] = 16'd2;

    assign flat_coeffs[6*16 +: 16] = 16'd1;
    assign flat_coeffs[7*16 +: 16] = 16'd2;
    assign flat_coeffs[8*16 +: 16] = 16'd1;

endmodule