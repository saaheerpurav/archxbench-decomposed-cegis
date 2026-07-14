`timescale 1ns/1ps

module ifft16_butterfly #(
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

    wire signed [MULT_W-1:0] b_re_cos;
    wire signed [MULT_W-1:0] b_im_sin;
    wire signed [MULT_W-1:0] b_re_sin;
    wire signed [MULT_W-1:0] b_im_cos;

    wire signed [ACC_W-1:0] round_q15;
    wire signed [ACC_W-1:0] rot_re_acc;
    wire signed [ACC_W-1:0] rot_im_acc;

    wire signed [DATA_W-1:0] rot_real;
    wire signed [DATA_W-1:0] rot_imag;

    assign round_q15 = {{(ACC_W-15){1'b0}}, 15'd16384};

    assign b_re_cos = b_real * tw_cos;
    assign b_im_sin = b_imag * tw_sin;
    assign b_re_sin = b_real * tw_sin;
    assign b_im_cos = b_imag * tw_cos;

    assign rot_re_acc =
        $signed({{(ACC_W-MULT_W){b_re_cos[MULT_W-1]}}, b_re_cos}) -
        $signed({{(ACC_W-MULT_W){b_im_sin[MULT_W-1]}}, b_im_sin}) +
        round_q15;

    assign rot_im_acc =
        $signed({{(ACC_W-MULT_W){b_re_sin[MULT_W-1]}}, b_re_sin}) +
        $signed({{(ACC_W-MULT_W){b_im_cos[MULT_W-1]}}, b_im_cos}) +
        round_q15;

    assign rot_real = rot_re_acc >>> 15;
    assign rot_imag = rot_im_acc >>> 15;

    assign y0_real = a_real + rot_real;
    assign y0_imag = a_imag + rot_imag;
    assign y1_real = a_real - rot_real;
    assign y1_imag = a_imag - rot_imag;

endmodule