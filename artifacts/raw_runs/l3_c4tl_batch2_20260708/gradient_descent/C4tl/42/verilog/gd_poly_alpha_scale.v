`timescale 1ns/1ps

module gd_poly_alpha_scale #(
    parameter N = 16,
    parameter M = 8
)(
    input  signed [N-1:0] alpha,
    input  signed [N-1:0] derivative,
    output signed [N-1:0] scaled_step
);

    wire signed [(2*N)-1:0] product;
    wire signed [(2*N)-1:0] rescaled_product;

    assign product = alpha * derivative;
    assign rescaled_product = product >>> M;
    assign scaled_step = rescaled_product[N-1:0];

endmodule