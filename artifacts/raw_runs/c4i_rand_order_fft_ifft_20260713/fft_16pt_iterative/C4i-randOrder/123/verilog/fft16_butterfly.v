`timescale 1ns/1ps

module fft16_butterfly #(
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

    localparam MULT_W = DATA_W + COEFF_W;
    localparam ACC_W  = MULT_W + 2;

    wire signed [MULT_W-1:0] mult_rr = b_real * tw_cos;
    wire signed [MULT_W-1:0] mult_is = b_imag * tw_sin;
    wire signed [MULT_W-1:0] mult_ic = b_imag * tw_cos;
    wire signed [MULT_W-1:0] mult_rs = b_real * tw_sin;

    wire signed [ACC_W-1:0] mult_rr_ext = {{(ACC_W-MULT_W){mult_rr[MULT_W-1]}}, mult_rr};
    wire signed [ACC_W-1:0] mult_is_ext = {{(ACC_W-MULT_W){mult_is[MULT_W-1]}}, mult_is};
    wire signed [ACC_W-1:0] mult_ic_ext = {{(ACC_W-MULT_W){mult_ic[MULT_W-1]}}, mult_ic};
    wire signed [ACC_W-1:0] mult_rs_ext = {{(ACC_W-MULT_W){mult_rs[MULT_W-1]}}, mult_rs};

    wire signed [ACC_W-1:0] round_q15 = {{(ACC_W-15){1'b0}}, 15'b100000000000000};

    wire signed [ACC_W-1:0] tr_real_acc = mult_rr_ext + mult_is_ext + round_q15;
    wire signed [ACC_W-1:0] tr_imag_acc = mult_ic_ext - mult_rs_ext + round_q15;

    wire signed [DATA_W-1:0] tr_real = tr_real_acc >>> 15;
    wire signed [DATA_W-1:0] tr_imag = tr_imag_acc >>> 15;

    assign y0_real = a_real + tr_real;
    assign y0_imag = a_imag + tr_imag;
    assign y1_real = a_real - tr_real;
    assign y1_imag = a_imag - tr_imag;

endmodule