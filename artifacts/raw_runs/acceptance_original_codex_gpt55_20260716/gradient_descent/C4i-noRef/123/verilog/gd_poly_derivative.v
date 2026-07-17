`timescale 1ns/1ps

module gd_poly_derivative #(
    parameter N = 16,
    parameter M = 8,
    parameter OUT_W = (2*N) + 1,
    parameter GRAD_W = OUT_W
)(
    input  signed [N-1:0] x,
    input  signed [N-1:0] a,
    input  signed [N-1:0] b,
    output signed [GRAD_W-1:0] gradient,
    output signed [GRAD_W-1:0] deriv
);

    localparam PROD_W = 2*N;
    localparam DBL_W  = PROD_W + 1;

    wire signed [PROD_W-1:0] ax_product;
    wire signed [DBL_W-1:0]  two_ax_product;
    wire signed [GRAD_W-1:0] two_ax_ext;
    wire signed [GRAD_W-1:0] scaled_two_ax;
    wire signed [GRAD_W-1:0] b_ext;
    wire signed [GRAD_W-1:0] derivative_value;

    assign ax_product = $signed(a) * $signed(x);

    assign two_ax_product = {ax_product[PROD_W-1], ax_product} <<< 1;
    assign two_ax_ext = {{(GRAD_W-DBL_W){two_ax_product[DBL_W-1]}}, two_ax_product};
    assign scaled_two_ax = two_ax_ext >>> M;

    assign b_ext = {{(GRAD_W-N){b[N-1]}}, b};

    assign derivative_value = scaled_two_ax + b_ext;

    assign gradient = derivative_value;
    assign deriv = derivative_value;

endmodule