`timescale 1ns/1ps

module ifft16_butterfly #(
    parameter WORK_W  = 20,
    parameter COEFF_W = 16
) (
    input  signed [WORK_W-1:0]  a_real,
    input  signed [WORK_W-1:0]  a_imag,
    input  signed [WORK_W-1:0]  b_real,
    input  signed [WORK_W-1:0]  b_imag,
    input  signed [COEFF_W-1:0] tw_cos,
    input  signed [COEFF_W-1:0] tw_sin,
    output signed [WORK_W-1:0]  p_real,
    output signed [WORK_W-1:0]  p_imag,
    output signed [WORK_W-1:0]  q_real,
    output signed [WORK_W-1:0]  q_imag
);

    localparam PROD_W = WORK_W + COEFF_W;
    localparam ACC_W  = PROD_W + 2;

    wire signed [PROD_W-1:0] br_cos_prod = b_real * tw_cos;
    wire signed [PROD_W-1:0] bi_sin_prod = b_imag * tw_sin;
    wire signed [PROD_W-1:0] br_sin_prod = b_real * tw_sin;
    wire signed [PROD_W-1:0] bi_cos_prod = b_imag * tw_cos;

    wire signed [ACC_W-1:0] br_cos = {{(ACC_W-PROD_W){br_cos_prod[PROD_W-1]}}, br_cos_prod};
    wire signed [ACC_W-1:0] bi_sin = {{(ACC_W-PROD_W){bi_sin_prod[PROD_W-1]}}, bi_sin_prod};
    wire signed [ACC_W-1:0] br_sin = {{(ACC_W-PROD_W){br_sin_prod[PROD_W-1]}}, br_sin_prod};
    wire signed [ACC_W-1:0] bi_cos = {{(ACC_W-PROD_W){bi_cos_prod[PROD_W-1]}}, bi_cos_prod};

    wire signed [ACC_W-1:0] round_const = {{(ACC_W-15){1'b0}}, 1'b1, 14'b0};

    wire signed [ACC_W-1:0] tr_wide = (br_cos - bi_sin + round_const) >>> 15;
    wire signed [ACC_W-1:0] ti_wide = (br_sin + bi_cos + round_const) >>> 15;

    wire signed [WORK_W-1:0] tr = tr_wide[WORK_W-1:0];
    wire signed [WORK_W-1:0] ti = ti_wide[WORK_W-1:0];

    assign p_real = a_real + tr;
    assign p_imag = a_imag + ti;
    assign q_real = a_real - tr;
    assign q_imag = a_imag - ti;

endmodule