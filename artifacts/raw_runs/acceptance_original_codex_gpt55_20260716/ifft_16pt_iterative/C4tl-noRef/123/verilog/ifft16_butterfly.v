`timescale 1ns/1ps

module ifft16_butterfly #(
    parameter DATA_W  = 12,
    parameter COEFF_W = 16,
    parameter GAIN_W  = 4
) (
    input  mode, // 0: FFT, 1: IFFT

    input  signed [DATA_W+GAIN_W-1:0] a_real,
    input  signed [DATA_W+GAIN_W-1:0] a_imag,
    input  signed [DATA_W+GAIN_W-1:0] b_real,
    input  signed [DATA_W+GAIN_W-1:0] b_imag,

    input  signed [COEFF_W-1:0] tw_cos,
    input  signed [COEFF_W-1:0] tw_sin,

    output signed [DATA_W+GAIN_W-1:0] out0_real,
    output signed [DATA_W+GAIN_W-1:0] out0_imag,
    output signed [DATA_W+GAIN_W-1:0] out1_real,
    output signed [DATA_W+GAIN_W-1:0] out1_imag
);

    localparam SAMPLE_W = DATA_W + GAIN_W;
    localparam PROD_W   = SAMPLE_W + COEFF_W;
    localparam ACC_W    = PROD_W + 2;

    wire signed [COEFF_W-1:0] eff_sin;
    assign eff_sin = mode ? tw_sin : -tw_sin;

    wire signed [PROD_W-1:0] br_cos;
    wire signed [PROD_W-1:0] bi_sin;
    wire signed [PROD_W-1:0] br_sin;
    wire signed [PROD_W-1:0] bi_cos;

    assign br_cos = b_real * tw_cos;
    assign bi_sin = b_imag * eff_sin;
    assign br_sin = b_real * eff_sin;
    assign bi_cos = b_imag * tw_cos;

    wire signed [ACC_W-1:0] rot_real_acc;
    wire signed [ACC_W-1:0] rot_imag_acc;

    assign rot_real_acc =
        {{(ACC_W-PROD_W){br_cos[PROD_W-1]}}, br_cos} -
        {{(ACC_W-PROD_W){bi_sin[PROD_W-1]}}, bi_sin} +
        {{(ACC_W-15){1'b0}}, 15'sd16384};

    assign rot_imag_acc =
        {{(ACC_W-PROD_W){br_sin[PROD_W-1]}}, br_sin} +
        {{(ACC_W-PROD_W){bi_cos[PROD_W-1]}}, bi_cos} +
        {{(ACC_W-15){1'b0}}, 15'sd16384};

    wire signed [SAMPLE_W-1:0] rot_real;
    wire signed [SAMPLE_W-1:0] rot_imag;

    assign rot_real = rot_real_acc >>> 15;
    assign rot_imag = rot_imag_acc >>> 15;

    assign out0_real = a_real + rot_real;
    assign out0_imag = a_imag + rot_imag;
    assign out1_real = a_real - rot_real;
    assign out1_imag = a_imag - rot_imag;

endmodule