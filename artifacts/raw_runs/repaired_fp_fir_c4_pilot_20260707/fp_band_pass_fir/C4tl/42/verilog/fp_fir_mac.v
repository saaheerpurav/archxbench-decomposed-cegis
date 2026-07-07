`timescale 1ns/1ps

module fp_fir_mac #(
    parameter TAP_CNT  = 31,
    parameter SAMPLE_Q = 20,
    parameter COEFF_Q  = 24,
    parameter ACC_W    = 64
) (
    input signed [31:0] s0,  input signed [31:0] c0,
    input signed [31:0] s1,  input signed [31:0] c1,
    input signed [31:0] s2,  input signed [31:0] c2,
    input signed [31:0] s3,  input signed [31:0] c3,
    input signed [31:0] s4,  input signed [31:0] c4,
    input signed [31:0] s5,  input signed [31:0] c5,
    input signed [31:0] s6,  input signed [31:0] c6,
    input signed [31:0] s7,  input signed [31:0] c7,
    input signed [31:0] s8,  input signed [31:0] c8,
    input signed [31:0] s9,  input signed [31:0] c9,
    input signed [31:0] s10, input signed [31:0] c10,
    input signed [31:0] s11, input signed [31:0] c11,
    input signed [31:0] s12, input signed [31:0] c12,
    input signed [31:0] s13, input signed [31:0] c13,
    input signed [31:0] s14, input signed [31:0] c14,
    input signed [31:0] s15, input signed [31:0] c15,
    input signed [31:0] s16, input signed [31:0] c16,
    input signed [31:0] s17, input signed [31:0] c17,
    input signed [31:0] s18, input signed [31:0] c18,
    input signed [31:0] s19, input signed [31:0] c19,
    input signed [31:0] s20, input signed [31:0] c20,
    input signed [31:0] s21, input signed [31:0] c21,
    input signed [31:0] s22, input signed [31:0] c22,
    input signed [31:0] s23, input signed [31:0] c23,
    input signed [31:0] s24, input signed [31:0] c24,
    input signed [31:0] s25, input signed [31:0] c25,
    input signed [31:0] s26, input signed [31:0] c26,
    input signed [31:0] s27, input signed [31:0] c27,
    input signed [31:0] s28, input signed [31:0] c28,
    input signed [31:0] s29, input signed [31:0] c29,
    input signed [31:0] s30, input signed [31:0] c30,
    output signed [ACC_W-1:0] accum
);
    wire signed [63:0] p0  = s0  * c0;
    wire signed [63:0] p1  = s1  * c1;
    wire signed [63:0] p2  = s2  * c2;
    wire signed [63:0] p3  = s3  * c3;
    wire signed [63:0] p4  = s4  * c4;
    wire signed [63:0] p5  = s5  * c5;
    wire signed [63:0] p6  = s6  * c6;
    wire signed [63:0] p7  = s7  * c7;
    wire signed [63:0] p8  = s8  * c8;
    wire signed [63:0] p9  = s9  * c9;
    wire signed [63:0] p10 = s10 * c10;
    wire signed [63:0] p11 = s11 * c11;
    wire signed [63:0] p12 = s12 * c12;
    wire signed [63:0] p13 = s13 * c13;
    wire signed [63:0] p14 = s14 * c14;
    wire signed [63:0] p15 = s15 * c15;
    wire signed [63:0] p16 = s16 * c16;
    wire signed [63:0] p17 = s17 * c17;
    wire signed [63:0] p18 = s18 * c18;
    wire signed [63:0] p19 = s19 * c19;
    wire signed [63:0] p20 = s20 * c20;
    wire signed [63:0] p21 = s21 * c21;
    wire signed [63:0] p22 = s22 * c22;
    wire signed [63:0] p23 = s23 * c23;
    wire signed [63:0] p24 = s24 * c24;
    wire signed [63:0] p25 = s25 * c25;
    wire signed [63:0] p26 = s26 * c26;
    wire signed [63:0] p27 = s27 * c27;
    wire signed [63:0] p28 = s28 * c28;
    wire signed [63:0] p29 = s29 * c29;
    wire signed [63:0] p30 = s30 * c30;

    assign accum =
        p0 + p1 + p2 + p3 + p4 + p5 + p6 + p7 +
        p8 + p9 + p10 + p11 + p12 + p13 + p14 + p15 +
        p16 + p17 + p18 + p19 + p20 + p21 + p22 + p23 +
        p24 + p25 + p26 + p27 + p28 + p29 + p30;
endmodule