`timescale 1ns/1ps

module gd_poly_gradient #(
    parameter N = 16,
    parameter M = 8,
    parameter W = 80
)(
    input  signed [W-1:0] x_val,
    input  signed [N-1:0] a,
    input  signed [N-1:0] b,
    output signed [W-1:0] gradient
);

    wire signed [W+N-1:0] ax_product;
    wire signed [W+N:0]   two_ax_product;
    wire signed [W+N:0]   scaled_two_ax;
    wire signed [W+N:0]   b_ext;
    wire signed [W+N:0]   gradient_ext;

    assign ax_product     = x_val * a;
    assign two_ax_product = {ax_product[W+N-1], ax_product} <<< 1;
    assign scaled_two_ax  = two_ax_product >>> M;
    assign b_ext          = {{(W+1){b[N-1]}}, b};
    assign gradient_ext   = scaled_two_ax + b_ext;

    assign gradient = gradient_ext[W-1:0];

endmodule