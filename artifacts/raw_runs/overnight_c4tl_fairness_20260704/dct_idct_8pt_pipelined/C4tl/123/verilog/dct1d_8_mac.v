`timescale 1ns/1ps

module dct1d_8_mac #(
    parameter DATA_W = 12,
    parameter COEFF_W = 16
) (
    input signed [DATA_W-1:0] s0,
    input signed [DATA_W-1:0] s1,
    input signed [DATA_W-1:0] s2,
    input signed [DATA_W-1:0] s3,
    input signed [DATA_W-1:0] s4,
    input signed [DATA_W-1:0] s5,
    input signed [DATA_W-1:0] s6,
    input signed [DATA_W-1:0] s7,
    input signed [COEFF_W-1:0] c0,
    input signed [COEFF_W-1:0] c1,
    input signed [COEFF_W-1:0] c2,
    input signed [COEFF_W-1:0] c3,
    input signed [COEFF_W-1:0] c4,
    input signed [COEFF_W-1:0] c5,
    input signed [COEFF_W-1:0] c6,
    input signed [COEFF_W-1:0] c7,
    output signed [DATA_W+COEFF_W+4:0] sum
);

    wire signed [DATA_W+COEFF_W-1:0] p0 = s0 * c0;
    wire signed [DATA_W+COEFF_W-1:0] p1 = s1 * c1;
    wire signed [DATA_W+COEFF_W-1:0] p2 = s2 * c2;
    wire signed [DATA_W+COEFF_W-1:0] p3 = s3 * c3;
    wire signed [DATA_W+COEFF_W-1:0] p4 = s4 * c4;
    wire signed [DATA_W+COEFF_W-1:0] p5 = s5 * c5;
    wire signed [DATA_W+COEFF_W-1:0] p6 = s6 * c6;
    wire signed [DATA_W+COEFF_W-1:0] p7 = s7 * c7;

    assign sum =
        {{5{p0[DATA_W+COEFF_W-1]}}, p0} +
        {{5{p1[DATA_W+COEFF_W-1]}}, p1} +
        {{5{p2[DATA_W+COEFF_W-1]}}, p2} +
        {{5{p3[DATA_W+COEFF_W-1]}}, p3} +
        {{5{p4[DATA_W+COEFF_W-1]}}, p4} +
        {{5{p5[DATA_W+COEFF_W-1]}}, p5} +
        {{5{p6[DATA_W+COEFF_W-1]}}, p6} +
        {{5{p7[DATA_W+COEFF_W-1]}}, p7};

endmodule