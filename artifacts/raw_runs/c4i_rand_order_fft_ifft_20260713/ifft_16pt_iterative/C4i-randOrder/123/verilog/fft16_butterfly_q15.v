`timescale 1ns/1ps

module fft16_butterfly_q15 #(
    parameter DATA_W  = 16,
    parameter COEFF_W = 16
) (
    input  signed [DATA_W-1:0]  a_real,
    input  signed [DATA_W-1:0]  a_imag,
    input  signed [DATA_W-1:0]  b_real,
    input  signed [DATA_W-1:0]  b_imag,
    input  signed [COEFF_W-1:0] tw_cos,
    input  signed [COEFF_W-1:0] tw_sin,
    output signed [DATA_W-1:0]  y0_real,
    output signed [DATA_W-1:0]  y0_imag,
    output signed [DATA_W-1:0]  y1_real,
    output signed [DATA_W-1:0]  y1_imag
);

    localparam integer MUL_W = DATA_W + COEFF_W;
    localparam integer ACC_W = MUL_W + 2;

    localparam signed [ACC_W-1:0] ROUND_Q15 = 16384;

    wire signed [MUL_W-1:0] br_cos = b_real * tw_cos;
    wire signed [MUL_W-1:0] bi_sin = b_imag * tw_sin;
    wire signed [MUL_W-1:0] br_sin = b_real * tw_sin;
    wire signed [MUL_W-1:0] bi_cos = b_imag * tw_cos;

    wire signed [ACC_W-1:0] br_cos_ext = {{(ACC_W-MUL_W){br_cos[MUL_W-1]}}, br_cos};
    wire signed [ACC_W-1:0] bi_sin_ext = {{(ACC_W-MUL_W){bi_sin[MUL_W-1]}}, bi_sin};
    wire signed [ACC_W-1:0] br_sin_ext = {{(ACC_W-MUL_W){br_sin[MUL_W-1]}}, br_sin};
    wire signed [ACC_W-1:0] bi_cos_ext = {{(ACC_W-MUL_W){bi_cos[MUL_W-1]}}, bi_cos};

    wire signed [ACC_W-1:0] rot_real_acc = br_cos_ext - bi_sin_ext + ROUND_Q15;
    wire signed [ACC_W-1:0] rot_imag_acc = br_sin_ext + bi_cos_ext + ROUND_Q15;

    wire signed [DATA_W-1:0] rot_real = rot_real_acc >>> 15;
    wire signed [DATA_W-1:0] rot_imag = rot_imag_acc >>> 15;

    assign y0_real = a_real + rot_real;
    assign y0_imag = a_imag + rot_imag;
    assign y1_real = a_real - rot_real;
    assign y1_imag = a_imag - rot_imag;

endmodule