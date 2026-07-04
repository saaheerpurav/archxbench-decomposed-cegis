`timescale 1ns/1ps

module ifft16_butterfly #(
    parameter DATA_W  = 16,
    parameter COEFF_W = 16,
    parameter OUT_W   = 16
) (
    input  signed [DATA_W-1:0]  a_real,
    input  signed [DATA_W-1:0]  a_imag,
    input  signed [DATA_W-1:0]  b_real,
    input  signed [DATA_W-1:0]  b_imag,
    input  signed [COEFF_W-1:0] tw_cos,
    input  signed [COEFF_W-1:0] tw_sin,
    output signed [OUT_W-1:0]   y0_real,
    output signed [OUT_W-1:0]   y0_imag,
    output signed [OUT_W-1:0]   y1_real,
    output signed [OUT_W-1:0]   y1_imag
);

    localparam PROD_W = DATA_W + COEFF_W;
    localparam ACC_W  = PROD_W + 2;
    localparam SUM_W  = OUT_W + 1;

    wire signed [PROD_W-1:0] b_real_w = {{COEFF_W{b_real[DATA_W-1]}}, b_real};
    wire signed [PROD_W-1:0] b_imag_w = {{COEFF_W{b_imag[DATA_W-1]}}, b_imag};
    wire signed [PROD_W-1:0] cos_w    = {{DATA_W{tw_cos[COEFF_W-1]}}, tw_cos};
    wire signed [PROD_W-1:0] sin_w    = {{DATA_W{tw_sin[COEFF_W-1]}}, tw_sin};

    wire signed [PROD_W-1:0] br_cos = b_real_w * cos_w;
    wire signed [PROD_W-1:0] bi_sin = b_imag_w * sin_w;
    wire signed [PROD_W-1:0] br_sin = b_real_w * sin_w;
    wire signed [PROD_W-1:0] bi_cos = b_imag_w * cos_w;

    wire signed [ACC_W-1:0] tr_acc =
        {{(ACC_W-PROD_W){br_cos[PROD_W-1]}}, br_cos} -
        {{(ACC_W-PROD_W){bi_sin[PROD_W-1]}}, bi_sin} +
        {{(ACC_W-15){1'b0}}, 15'b100000000000000};

    wire signed [ACC_W-1:0] ti_acc =
        {{(ACC_W-PROD_W){br_sin[PROD_W-1]}}, br_sin} +
        {{(ACC_W-PROD_W){bi_cos[PROD_W-1]}}, bi_cos} +
        {{(ACC_W-15){1'b0}}, 15'b100000000000000};

    wire signed [OUT_W-1:0] tr = tr_acc >>> 15;
    wire signed [OUT_W-1:0] ti = ti_acc >>> 15;

    wire signed [OUT_W-1:0] a_real_w = {{(OUT_W-DATA_W){a_real[DATA_W-1]}}, a_real};
    wire signed [OUT_W-1:0] a_imag_w = {{(OUT_W-DATA_W){a_imag[DATA_W-1]}}, a_imag};

    wire signed [SUM_W-1:0] y0r = {a_real_w[OUT_W-1], a_real_w} + {tr[OUT_W-1], tr};
    wire signed [SUM_W-1:0] y0i = {a_imag_w[OUT_W-1], a_imag_w} + {ti[OUT_W-1], ti};
    wire signed [SUM_W-1:0] y1r = {a_real_w[OUT_W-1], a_real_w} - {tr[OUT_W-1], tr};
    wire signed [SUM_W-1:0] y1i = {a_imag_w[OUT_W-1], a_imag_w} - {ti[OUT_W-1], ti};

    assign y0_real = y0r[OUT_W-1:0];
    assign y0_imag = y0i[OUT_W-1:0];
    assign y1_real = y1r[OUT_W-1:0];
    assign y1_imag = y1i[OUT_W-1:0];

endmodule