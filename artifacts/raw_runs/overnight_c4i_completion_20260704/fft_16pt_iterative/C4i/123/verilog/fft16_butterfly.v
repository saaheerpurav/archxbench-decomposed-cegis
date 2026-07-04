`timescale 1ns/1ps

module fft16_butterfly #(
    parameter DATA_W = 16,
    parameter COEFF_W = 16
) (
    input mode,
    input signed [DATA_W-1:0] a_real,
    input signed [DATA_W-1:0] a_imag,
    input signed [DATA_W-1:0] b_real,
    input signed [DATA_W-1:0] b_imag,
    input signed [COEFF_W-1:0] tw_cos,
    input signed [COEFF_W-1:0] tw_sin,
    output signed [DATA_W-1:0] y0_real,
    output signed [DATA_W-1:0] y0_imag,
    output signed [DATA_W-1:0] y1_real,
    output signed [DATA_W-1:0] y1_imag
);

    localparam PROD_W = DATA_W + COEFF_W;
    localparam SUM_W  = PROD_W + 2;
    localparam signed [SUM_W-1:0] ROUND_Q15 = 16'sd16384;

    wire signed [PROD_W-1:0] br_cos_prod = b_real * tw_cos;
    wire signed [PROD_W-1:0] bi_sin_prod = b_imag * tw_sin;
    wire signed [PROD_W-1:0] bi_cos_prod = b_imag * tw_cos;
    wire signed [PROD_W-1:0] br_sin_prod = b_real * tw_sin;

    wire signed [SUM_W-1:0] br_cos = br_cos_prod;
    wire signed [SUM_W-1:0] bi_sin = bi_sin_prod;
    wire signed [SUM_W-1:0] bi_cos = bi_cos_prod;
    wire signed [SUM_W-1:0] br_sin = br_sin_prod;

    wire signed [SUM_W-1:0] tr_real_full =
        mode ? (br_cos - bi_sin + ROUND_Q15)
             : (br_cos + bi_sin + ROUND_Q15);

    wire signed [SUM_W-1:0] tr_imag_full =
        mode ? (bi_cos + br_sin + ROUND_Q15)
             : (bi_cos - br_sin + ROUND_Q15);

    wire signed [DATA_W-1:0] tr_real = tr_real_full >>> 15;
    wire signed [DATA_W-1:0] tr_imag = tr_imag_full >>> 15;

    assign y0_real = a_real + tr_real;
    assign y0_imag = a_imag + tr_imag;
    assign y1_real = a_real - tr_real;
    assign y1_imag = a_imag - tr_imag;

endmodule