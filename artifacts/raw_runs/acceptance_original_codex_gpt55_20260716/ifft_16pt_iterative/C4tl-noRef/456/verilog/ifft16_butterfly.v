`timescale 1ns/1ps

module ifft16_butterfly #(
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

    localparam MUL_W = DATA_W + COEFF_W;
    localparam ACC_W = MUL_W + 1;

    wire signed [MUL_W-1:0] mult_rr = b_real * tw_real;
    wire signed [MUL_W-1:0] mult_ii = b_imag * tw_imag;
    wire signed [MUL_W-1:0] mult_ri = b_real * tw_imag;
    wire signed [MUL_W-1:0] mult_ir = b_imag * tw_real;

    wire signed [ACC_W-1:0] rot_real_acc =
        {{1{mult_rr[MUL_W-1]}}, mult_rr} -
        {{1{mult_ii[MUL_W-1]}}, mult_ii};

    wire signed [ACC_W-1:0] rot_imag_acc =
        {{1{mult_ri[MUL_W-1]}}, mult_ri} +
        {{1{mult_ir[MUL_W-1]}}, mult_ir};

    wire signed [ACC_W-1:0] round_bias = {{(ACC_W-15){1'b0}}, 15'sd16384};

    wire signed [ACC_W-1:0] rot_real_q15 = (rot_real_acc + round_bias) >>> 15;
    wire signed [ACC_W-1:0] rot_imag_q15 = (rot_imag_acc + round_bias) >>> 15;

    wire signed [DATA_W:0] a_real_ext = {a_real[DATA_W-1], a_real};
    wire signed [DATA_W:0] a_imag_ext = {a_imag[DATA_W-1], a_imag};

    wire signed [DATA_W:0] rot_real = rot_real_q15[DATA_W:0];
    wire signed [DATA_W:0] rot_imag = rot_imag_q15[DATA_W:0];

    assign y0_real = a_real_ext + rot_real;
    assign y0_imag = a_imag_ext + rot_imag;
    assign y1_real = a_real_ext - rot_real;
    assign y1_imag = a_imag_ext - rot_imag;

endmodule