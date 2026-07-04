`timescale 1ns/1ps

module dct_mac8 #(
    parameter DATA_W = 12,
    parameter COEFF_W = 16,
    parameter ACC_W = DATA_W + COEFF_W + 4
) (
    input signed [DATA_W-1:0] x0,
    input signed [DATA_W-1:0] x1,
    input signed [DATA_W-1:0] x2,
    input signed [DATA_W-1:0] x3,
    input signed [DATA_W-1:0] x4,
    input signed [DATA_W-1:0] x5,
    input signed [DATA_W-1:0] x6,
    input signed [DATA_W-1:0] x7,
    input signed [COEFF_W-1:0] c0,
    input signed [COEFF_W-1:0] c1,
    input signed [COEFF_W-1:0] c2,
    input signed [COEFF_W-1:0] c3,
    input signed [COEFF_W-1:0] c4,
    input signed [COEFF_W-1:0] c5,
    input signed [COEFF_W-1:0] c6,
    input signed [COEFF_W-1:0] c7,
    output signed [ACC_W-1:0] sum
);

    wire signed [DATA_W+COEFF_W-1:0] p0 = x0 * c0;
    wire signed [DATA_W+COEFF_W-1:0] p1 = x1 * c1;
    wire signed [DATA_W+COEFF_W-1:0] p2 = x2 * c2;
    wire signed [DATA_W+COEFF_W-1:0] p3 = x3 * c3;
    wire signed [DATA_W+COEFF_W-1:0] p4 = x4 * c4;
    wire signed [DATA_W+COEFF_W-1:0] p5 = x5 * c5;
    wire signed [DATA_W+COEFF_W-1:0] p6 = x6 * c6;
    wire signed [DATA_W+COEFF_W-1:0] p7 = x7 * c7;

    assign sum =
        {{(ACC_W-(DATA_W+COEFF_W)){p0[DATA_W+COEFF_W-1]}}, p0} +
        {{(ACC_W-(DATA_W+COEFF_W)){p1[DATA_W+COEFF_W-1]}}, p1} +
        {{(ACC_W-(DATA_W+COEFF_W)){p2[DATA_W+COEFF_W-1]}}, p2} +
        {{(ACC_W-(DATA_W+COEFF_W)){p3[DATA_W+COEFF_W-1]}}, p3} +
        {{(ACC_W-(DATA_W+COEFF_W)){p4[DATA_W+COEFF_W-1]}}, p4} +
        {{(ACC_W-(DATA_W+COEFF_W)){p5[DATA_W+COEFF_W-1]}}, p5} +
        {{(ACC_W-(DATA_W+COEFF_W)){p6[DATA_W+COEFF_W-1]}}, p6} +
        {{(ACC_W-(DATA_W+COEFF_W)){p7[DATA_W+COEFF_W-1]}}, p7};

endmodule