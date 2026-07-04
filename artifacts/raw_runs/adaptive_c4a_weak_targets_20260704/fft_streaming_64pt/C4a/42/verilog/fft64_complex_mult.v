`timescale 1ns/1ps

module fft64_complex_mult #(
    parameter DATA_W = 20,
    parameter TW_W   = 16
) (
    input  signed [DATA_W-1:0] a_real,
    input  signed [DATA_W-1:0] a_imag,
    input  signed [TW_W-1:0]   b_real,
    input  signed [TW_W-1:0]   b_imag,
    output signed [DATA_W-1:0] p_real,
    output signed [DATA_W-1:0] p_imag
);

    localparam PROD_W = DATA_W + TW_W;
    localparam FULL_W = PROD_W + 1;

    wire signed [PROD_W-1:0] rr_prod = a_real * b_real;
    wire signed [PROD_W-1:0] ii_prod = a_imag * b_imag;
    wire signed [PROD_W-1:0] ri_prod = a_real * b_imag;
    wire signed [PROD_W-1:0] ir_prod = a_imag * b_real;

    wire signed [FULL_W-1:0] rr = {rr_prod[PROD_W-1], rr_prod};
    wire signed [FULL_W-1:0] ii = {ii_prod[PROD_W-1], ii_prod};
    wire signed [FULL_W-1:0] ri = {ri_prod[PROD_W-1], ri_prod};
    wire signed [FULL_W-1:0] ir = {ir_prod[PROD_W-1], ir_prod};

    wire signed [FULL_W-1:0] real_full = rr - ii;
    wire signed [FULL_W-1:0] imag_full = ri + ir;

    assign p_real = real_full >>> 15;
    assign p_imag = imag_full >>> 15;

endmodule