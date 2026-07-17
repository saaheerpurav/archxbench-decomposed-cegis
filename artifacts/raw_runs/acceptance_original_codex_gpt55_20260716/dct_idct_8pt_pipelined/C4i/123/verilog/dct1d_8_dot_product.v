`timescale 1ns/1ps

module dct1d_8_dot_product #(
    parameter DATA_W = 12,
    parameter COEFF_W = 16,
    parameter ACC_W = DATA_W + COEFF_W + 4
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
    output signed [ACC_W-1:0] acc
);

    localparam PROD_W = DATA_W + COEFF_W;

    wire signed [PROD_W-1:0] p0 = $signed(s0) * $signed(c0);
    wire signed [PROD_W-1:0] p1 = $signed(s1) * $signed(c1);
    wire signed [PROD_W-1:0] p2 = $signed(s2) * $signed(c2);
    wire signed [PROD_W-1:0] p3 = $signed(s3) * $signed(c3);
    wire signed [PROD_W-1:0] p4 = $signed(s4) * $signed(c4);
    wire signed [PROD_W-1:0] p5 = $signed(s5) * $signed(c5);
    wire signed [PROD_W-1:0] p6 = $signed(s6) * $signed(c6);
    wire signed [PROD_W-1:0] p7 = $signed(s7) * $signed(c7);

    wire signed [ACC_W-1:0] a0 = {{(ACC_W-PROD_W){p0[PROD_W-1]}}, p0};
    wire signed [ACC_W-1:0] a1 = {{(ACC_W-PROD_W){p1[PROD_W-1]}}, p1};
    wire signed [ACC_W-1:0] a2 = {{(ACC_W-PROD_W){p2[PROD_W-1]}}, p2};
    wire signed [ACC_W-1:0] a3 = {{(ACC_W-PROD_W){p3[PROD_W-1]}}, p3};
    wire signed [ACC_W-1:0] a4 = {{(ACC_W-PROD_W){p4[PROD_W-1]}}, p4};
    wire signed [ACC_W-1:0] a5 = {{(ACC_W-PROD_W){p5[PROD_W-1]}}, p5};
    wire signed [ACC_W-1:0] a6 = {{(ACC_W-PROD_W){p6[PROD_W-1]}}, p6};
    wire signed [ACC_W-1:0] a7 = {{(ACC_W-PROD_W){p7[PROD_W-1]}}, p7};

    assign acc = a0 + a1 + a2 + a3 + a4 + a5 + a6 + a7;

endmodule