`timescale 1ns/1ps

module gd_signed_multiplier #(
    parameter N = 16
)(
    input  signed [N-1:0]     a,
    input  signed [N-1:0]     b,
    output signed [(2*N)-1:0] product
);

    assign product = a * b;

endmodule