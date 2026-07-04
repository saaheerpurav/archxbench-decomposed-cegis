`timescale 1ns/1ps

module dct_mac8 #(
    parameter DATA_W = 12,
    parameter COEFF_W = 16,
    parameter ACC_W = 32
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
    output signed [ACC_W-1:0] sum
);

    localparam PROD_W = DATA_W + COEFF_W;

    wire signed [PROD_W-1:0] p0 = s0 * c0;
    wire signed [PROD_W-1:0] p1 = s1 * c1;
    wire signed [PROD_W-1:0] p2 = s2 * c2;
    wire signed [PROD_W-1:0] p3 = s3 * c3;
    wire signed [PROD_W-1:0] p4 = s4 * c4;
    wire signed [PROD_W-1:0] p5 = s5 * c5;
    wire signed [PROD_W-1:0] p6 = s6 * c6;
    wire signed [PROD_W-1:0] p7 = s7 * c7;

    assign sum =
        {{(ACC_W-PROD_W){p0[PROD_W-1]}}, p0} +
        {{(ACC_W-PROD_W){p1[PROD_W-1]}}, p1} +
        {{(ACC_W-PROD_W){p2[PROD_W-1]}}, p2} +
        {{(ACC_W-PROD_W){p3[PROD_W-1]}}, p3} +
        {{(ACC_W-PROD_W){p4[PROD_W-1]}}, p4} +
        {{(ACC_W-PROD_W){p5[PROD_W-1]}}, p5} +
        {{(ACC_W-PROD_W){p6[PROD_W-1]}}, p6} +
        {{(ACC_W-PROD_W){p7[PROD_W-1]}}, p7};

endmodule