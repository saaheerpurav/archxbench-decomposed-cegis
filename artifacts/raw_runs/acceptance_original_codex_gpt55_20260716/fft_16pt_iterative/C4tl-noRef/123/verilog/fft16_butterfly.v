`timescale 1ns/1ps

module fft16_butterfly #(
    parameter DATA_W  = 12,
    parameter COEFF_W = 16,
    parameter GAIN_W  = 4,
    parameter IN_W    = DATA_W + GAIN_W,
    parameter OUT_W   = DATA_W + GAIN_W
) (
    input  mode, // 0: FFT, 1: IFFT

    input  signed [IN_W-1:0]    a_real,
    input  signed [IN_W-1:0]    a_imag,
    input  signed [IN_W-1:0]    b_real,
    input  signed [IN_W-1:0]    b_imag,

    input  signed [COEFF_W-1:0] tw_cos,
    input  signed [COEFF_W-1:0] tw_sin,

    output signed [OUT_W-1:0]   y0_real,
    output signed [OUT_W-1:0]   y0_imag,
    output signed [OUT_W-1:0]   y1_real,
    output signed [OUT_W-1:0]   y1_imag
);

    localparam EXT_COEFF_W = COEFF_W + 1;
    localparam PROD_W      = IN_W + EXT_COEFF_W;
    localparam ACC_W       = PROD_W + 1;

    wire signed [EXT_COEFF_W-1:0] cos_ext;
    wire signed [EXT_COEFF_W-1:0] sin_ext;
    wire signed [EXT_COEFF_W-1:0] sin_eff;

    assign cos_ext = {tw_cos[COEFF_W-1], tw_cos};
    assign sin_ext = {tw_sin[COEFF_W-1], tw_sin};

    // FFT:  cos - j*sin
    // IFFT: cos + j*sin
    assign sin_eff = mode ? -sin_ext : sin_ext;

    wire signed [PROD_W-1:0] br_cos;
    wire signed [PROD_W-1:0] bi_sin;
    wire signed [PROD_W-1:0] bi_cos;
    wire signed [PROD_W-1:0] br_sin;

    assign br_cos = b_real * cos_ext;
    assign bi_sin = b_imag * sin_eff;
    assign bi_cos = b_imag * cos_ext;
    assign br_sin = b_real * sin_eff;

    wire signed [ACC_W-1:0] real_acc;
    wire signed [ACC_W-1:0] imag_acc;

    assign real_acc = br_cos + bi_sin + {{(ACC_W-15){1'b0}}, 15'sd16384};
    assign imag_acc = bi_cos - br_sin + {{(ACC_W-15){1'b0}}, 15'sd16384};

    wire signed [ACC_W-1:0] tr_real_ext;
    wire signed [ACC_W-1:0] tr_imag_ext;

    assign tr_real_ext = real_acc >>> 15;
    assign tr_imag_ext = imag_acc >>> 15;

    wire signed [OUT_W-1:0] tr_real;
    wire signed [OUT_W-1:0] tr_imag;
    wire signed [OUT_W-1:0] a_real_out;
    wire signed [OUT_W-1:0] a_imag_out;

    assign tr_real   = tr_real_ext[OUT_W-1:0];
    assign tr_imag   = tr_imag_ext[OUT_W-1:0];
    assign a_real_out = a_real[OUT_W-1:0];
    assign a_imag_out = a_imag[OUT_W-1:0];

    assign y0_real = a_real_out + tr_real;
    assign y0_imag = a_imag_out + tr_imag;
    assign y1_real = a_real_out - tr_real;
    assign y1_imag = a_imag_out - tr_imag;

endmodule