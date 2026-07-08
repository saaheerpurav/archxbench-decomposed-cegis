`timescale 1ns/1ps

module gs_iteration #(
    parameter DATA_WIDTH = 32,
    parameter FRAC = 16
)(
    input  [DATA_WIDTH-1:0] a12,
    input  [DATA_WIDTH-1:0] a21,
    input  [DATA_WIDTH-1:0] b1,
    input  [DATA_WIDTH-1:0] b2,
    input  [DATA_WIDTH-1:0] x1_current,
    input  [DATA_WIDTH-1:0] x2_current,
    input  [DATA_WIDTH-1:0] inv_a11,
    input  [DATA_WIDTH-1:0] inv_a22,
    output [DATA_WIDTH-1:0] x1_next,
    output [DATA_WIDTH-1:0] x2_next
);

    wire signed [DATA_WIDTH-1:0] a12_x2;
    wire signed [DATA_WIDTH-1:0] a21_x1_next;
    wire signed [DATA_WIDTH-1:0] rhs1;
    wire signed [DATA_WIDTH-1:0] rhs2;

    assign rhs1 = $signed(b1) - a12_x2;
    assign rhs2 = $signed(b2) - a21_x1_next;

    gs_fixed_mul #(
        .DATA_WIDTH(DATA_WIDTH),
        .FRAC(FRAC)
    ) u_mul_a12_x2 (
        .lhs(a12),
        .rhs(x2_current),
        .product(a12_x2)
    );

    gs_fixed_mul #(
        .DATA_WIDTH(DATA_WIDTH),
        .FRAC(FRAC)
    ) u_mul_rhs1_inv (
        .lhs(rhs1),
        .rhs(inv_a11),
        .product(x1_next)
    );

    gs_fixed_mul #(
        .DATA_WIDTH(DATA_WIDTH),
        .FRAC(FRAC)
    ) u_mul_a21_x1_next (
        .lhs(a21),
        .rhs(x1_next),
        .product(a21_x1_next)
    );

    gs_fixed_mul #(
        .DATA_WIDTH(DATA_WIDTH),
        .FRAC(FRAC)
    ) u_mul_rhs2_inv (
        .lhs(rhs2),
        .rhs(inv_a22),
        .product(x2_next)
    );

endmodule