`timescale 1ns/1ps

module gd_poly_step #(
    parameter N = 16,
    parameter M = 8,
    parameter W = 80
)(
    input  signed [N-1:0] alpha,
    input  signed [W-1:0] gradient,
    output signed [W-1:0] step
);

    wire signed [W+N-1:0] product;
    wire signed [W+N-1:0] scaled_product;

    assign product = gradient * alpha;
    assign scaled_product = product >>> M;
    assign step = scaled_product[W-1:0];

endmodule