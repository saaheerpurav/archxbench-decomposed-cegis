`timescale 1ns/1ps

module fft16_butterfly #(
    parameter DATA_W  = 16,
    parameter COEFF_W = 16
) (
    input  mode,
    input  signed [DATA_W-1:0]  a_real,
    input  signed [DATA_W-1:0]  a_imag,
    input  signed [DATA_W-1:0]  b_real,
    input  signed [DATA_W-1:0]  b_imag,
    input  signed [COEFF_W-1:0] tw_cos,
    input  signed [COEFF_W-1:0] tw_sin,
    output signed [DATA_W-1:0]  y_a_real,
    output signed [DATA_W-1:0]  y_a_imag,
    output signed [DATA_W-1:0]  y_b_real,
    output signed [DATA_W-1:0]  y_b_imag
);

    localparam FRAC_W = COEFF_W - 1;
    localparam SIN_W  = COEFF_W + 1;
    localparam PROD_W = DATA_W + SIN_W + 2;

    wire signed [SIN_W-1:0] cos_eff = {tw_cos[COEFF_W-1], tw_cos};
    wire signed [SIN_W-1:0] sin_ext = {tw_sin[COEFF_W-1], tw_sin};
    wire signed [SIN_W-1:0] sin_eff = mode ? -sin_ext : sin_ext;

    wire signed [PROD_W-1:0] br_cos = b_real * cos_eff;
    wire signed [PROD_W-1:0] bi_sin = b_imag * sin_eff;
    wire signed [PROD_W-1:0] bi_cos = b_imag * cos_eff;
    wire signed [PROD_W-1:0] br_sin = b_real * sin_eff;

    wire signed [PROD_W-1:0] round_const =
        {{(PROD_W-FRAC_W){1'b0}}, 1'b1, {(FRAC_W-1){1'b0}}};

    wire signed [PROD_W-1:0] tr_real_wide =
        (br_cos + bi_sin + round_const) >>> FRAC_W;
    wire signed [PROD_W-1:0] tr_imag_wide =
        (bi_cos - br_sin + round_const) >>> FRAC_W;

    wire signed [DATA_W-1:0] tr_real = tr_real_wide[DATA_W-1:0];
    wire signed [DATA_W-1:0] tr_imag = tr_imag_wide[DATA_W-1:0];

    assign y_a_real = a_real + tr_real;
    assign y_a_imag = a_imag + tr_imag;
    assign y_b_real = a_real - tr_real;
    assign y_b_imag = a_imag - tr_imag;

endmodule