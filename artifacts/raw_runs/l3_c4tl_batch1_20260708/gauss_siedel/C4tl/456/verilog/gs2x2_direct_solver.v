`timescale 1ns/1ps

module gs2x2_direct_solver #(
    parameter DATA_WIDTH = 32,
    parameter FRAC = 16
)(
    input [DATA_WIDTH-1:0] a11,
    input [DATA_WIDTH-1:0] a12,
    input [DATA_WIDTH-1:0] a21,
    input [DATA_WIDTH-1:0] a22,
    input [DATA_WIDTH-1:0] b1,
    input [DATA_WIDTH-1:0] b2,
    output [DATA_WIDTH-1:0] x1,
    output [DATA_WIDTH-1:0] x2,
    output valid
);

    wire signed [DATA_WIDTH-1:0] s_a11 = a11;
    wire signed [DATA_WIDTH-1:0] s_a12 = a12;
    wire signed [DATA_WIDTH-1:0] s_a21 = a21;
    wire signed [DATA_WIDTH-1:0] s_a22 = a22;
    wire signed [DATA_WIDTH-1:0] s_b1  = b1;
    wire signed [DATA_WIDTH-1:0] s_b2  = b2;

    wire signed [(2*DATA_WIDTH)-1:0] det_term1 = s_a11 * s_a22;
    wire signed [(2*DATA_WIDTH)-1:0] det_term2 = s_a12 * s_a21;
    wire signed [(2*DATA_WIDTH)-1:0] det = det_term1 - det_term2;

    wire signed [(2*DATA_WIDTH)-1:0] x1_num = (s_b1 * s_a22) - (s_a12 * s_b2);
    wire signed [(2*DATA_WIDTH)-1:0] x2_num = (s_a11 * s_b2) - (s_b1 * s_a21);

    gs2x2_signed_divider #(
        .DATA_WIDTH(DATA_WIDTH),
        .FRAC(FRAC)
    ) div_x1 (
        .numerator(x1_num),
        .denominator(det),
        .quotient(x1)
    );

    gs2x2_signed_divider #(
        .DATA_WIDTH(DATA_WIDTH),
        .FRAC(FRAC)
    ) div_x2 (
        .numerator(x2_num),
        .denominator(det),
        .quotient(x2)
    );

    assign valid = (det != 0);

endmodule