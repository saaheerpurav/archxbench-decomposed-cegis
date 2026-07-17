`timescale 1ns/1ps

module fft16_butterfly #(
    parameter DATA_W  = 16,
    parameter COEFF_W = 16
) (
    input  signed [DATA_W-1:0]  a_real,
    input  signed [DATA_W-1:0]  a_imag,
    input  signed [DATA_W-1:0]  b_real,
    input  signed [DATA_W-1:0]  b_imag,
    input  signed [COEFF_W-1:0] tw_real,
    input  signed [COEFF_W-1:0] tw_imag,

    output signed [DATA_W:0]    y0_real,
    output signed [DATA_W:0]    y0_imag,
    output signed [DATA_W:0]    y1_real,
    output signed [DATA_W:0]    y1_imag
);

    localparam PROD_W = DATA_W + COEFF_W;
    localparam ACC_W  = PROD_W + 1;

    wire signed [PROD_W-1:0] br_wr = b_real * tw_real;
    wire signed [PROD_W-1:0] bi_wi = b_imag * tw_imag;
    wire signed [PROD_W-1:0] br_wi = b_real * tw_imag;
    wire signed [PROD_W-1:0] bi_wr = b_imag * tw_real;

    wire signed [ACC_W-1:0] round_const = {{(ACC_W-15){1'b0}}, 15'sd16384};

    wire signed [ACC_W-1:0] tr_acc =
        {{1{br_wr[PROD_W-1]}}, br_wr} -
        {{1{bi_wi[PROD_W-1]}}, bi_wi} +
        round_const;

    wire signed [ACC_W-1:0] ti_acc =
        {{1{br_wi[PROD_W-1]}}, br_wi} +
        {{1{bi_wr[PROD_W-1]}}, bi_wr} +
        round_const;

    wire signed [DATA_W:0] tr = tr_acc >>> 15;
    wire signed [DATA_W:0] ti = ti_acc >>> 15;

    wire signed [DATA_W:0] a_real_ext = {a_real[DATA_W-1], a_real};
    wire signed [DATA_W:0] a_imag_ext = {a_imag[DATA_W-1], a_imag};

    assign y0_real = a_real_ext + tr;
    assign y0_imag = a_imag_ext + ti;
    assign y1_real = a_real_ext - tr;
    assign y1_imag = a_imag_ext - ti;

endmodule