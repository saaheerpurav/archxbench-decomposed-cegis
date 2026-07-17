`timescale 1ns/1ps

module gs_iteration_2x2 #(
    parameter DATA_WIDTH = 32,
    parameter FRAC = 16
)(
    input signed [DATA_WIDTH-1:0] a12,
    input signed [DATA_WIDTH-1:0] a21,
    input signed [DATA_WIDTH-1:0] b1,
    input signed [DATA_WIDTH-1:0] b2,
    input signed [DATA_WIDTH-1:0] inv_a11,
    input signed [DATA_WIDTH-1:0] inv_a22,
    input signed [DATA_WIDTH-1:0] x1_current,
    input signed [DATA_WIDTH-1:0] x2_current,
    output signed [DATA_WIDTH-1:0] x1_next,
    output signed [DATA_WIDTH-1:0] x2_next
);
    wire signed [DATA_WIDTH-1:0] a12_x2;
    wire signed [DATA_WIDTH-1:0] a21_x1_next;
    wire signed [DATA_WIDTH-1:0] x1_residual;
    wire signed [DATA_WIDTH-1:0] x2_residual;

    assign x1_residual = b1 - a12_x2;
    assign x2_residual = b2 - a21_x1_next;

    gs_fixed_mul #(
        .DATA_WIDTH(DATA_WIDTH),
        .FRAC(FRAC)
    ) mul_a12_x2 (
        .lhs(a12),
        .rhs(x2_current),
        .product(a12_x2)
    );

    gs_fixed_mul #(
        .DATA_WIDTH(DATA_WIDTH),
        .FRAC(FRAC)
    ) mul_x1 (
        .lhs(x1_residual),
        .rhs(inv_a11),
        .product(x1_next)
    );

    gs_fixed_mul #(
        .DATA_WIDTH(DATA_WIDTH),
        .FRAC(FRAC)
    ) mul_a21_x1 (
        .lhs(a21),
        .rhs(x1_next),
        .product(a21_x1_next)
    );

    gs_fixed_mul #(
        .DATA_WIDTH(DATA_WIDTH),
        .FRAC(FRAC)
    ) mul_x2 (
        .lhs(x2_residual),
        .rhs(inv_a22),
        .product(x2_next)
    );

endmodule