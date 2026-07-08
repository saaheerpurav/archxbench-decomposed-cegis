`timescale 1ns/1ps

module gs2x2_direct_solver #(
    parameter DATA_WIDTH = 32,
    parameter FRAC = 16
)(
    input signed [DATA_WIDTH-1:0] a11,
    input signed [DATA_WIDTH-1:0] a12,
    input signed [DATA_WIDTH-1:0] a21,
    input signed [DATA_WIDTH-1:0] a22,
    input signed [DATA_WIDTH-1:0] b1,
    input signed [DATA_WIDTH-1:0] b2,
    output signed [DATA_WIDTH-1:0] x1,
    output signed [DATA_WIDTH-1:0] x2,
    output valid
);

    wire signed [(2*DATA_WIDTH)-1:0] det;
    wire signed [(2*DATA_WIDTH)-1:0] num_x1;
    wire signed [(2*DATA_WIDTH)-1:0] num_x2;

    gs2x2_determinant #(
        .DATA_WIDTH(DATA_WIDTH)
    ) determinant_unit (
        .a11(a11),
        .a12(a12),
        .a21(a21),
        .a22(a22),
        .det(det)
    );

    gs2x2_numerators #(
        .DATA_WIDTH(DATA_WIDTH)
    ) numerator_unit (
        .a11(a11),
        .a12(a12),
        .a21(a21),
        .a22(a22),
        .b1(b1),
        .b2(b2),
        .num_x1(num_x1),
        .num_x2(num_x2)
    );

    gs2x2_fixed_divider #(
        .DATA_WIDTH(DATA_WIDTH),
        .FRAC(FRAC)
    ) div_x1 (
        .numerator(num_x1),
        .denominator(det),
        .quotient(x1)
    );

    gs2x2_fixed_divider #(
        .DATA_WIDTH(DATA_WIDTH),
        .FRAC(FRAC)
    ) div_x2 (
        .numerator(num_x2),
        .denominator(det),
        .quotient(x2)
    );

    assign valid = (det != {2*DATA_WIDTH{1'b0}});

endmodule