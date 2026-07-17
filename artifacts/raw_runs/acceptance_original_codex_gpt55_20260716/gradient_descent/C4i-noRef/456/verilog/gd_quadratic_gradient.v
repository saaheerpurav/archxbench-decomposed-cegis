`timescale 1ns/1ps

module gd_quadratic_gradient #(
    parameter N = 16,
    parameter M = 8
)(
    input  signed [N-1:0] x,
    input  signed [N-1:0] a,
    input  signed [N-1:0] b,
    output signed [N-1:0] gradient
);

    wire signed [(2*N)-1:0] ax_product;
    wire signed [(2*N):0] doubled_product;
    wire signed [(2*N):0] scaled_product;
    wire signed [(2*N):0] extended_b;
    wire signed [(2*N):0] gradient_full;

    assign ax_product      = a * x;
    assign doubled_product = {ax_product[(2*N)-1], ax_product} <<< 1;
    assign scaled_product  = doubled_product >>> M;
    assign extended_b      = {{(N+1){b[N-1]}}, b};
    assign gradient_full   = scaled_product + extended_b;

    assign gradient = gradient_full[N-1:0];

endmodule