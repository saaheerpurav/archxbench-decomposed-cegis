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

    output signed [DATA_W-1:0]  y0_real,
    output signed [DATA_W-1:0]  y0_imag,
    output signed [DATA_W-1:0]  y1_real,
    output signed [DATA_W-1:0]  y1_imag
);

    localparam PROD_W = DATA_W + COEFF_W;
    localparam ACC_W  = PROD_W + 2;

    wire signed [PROD_W-1:0] prod_rr = b_real * tw_cos;
    wire signed [PROD_W-1:0] prod_ii = b_imag * tw_sin;
    wire signed [PROD_W-1:0] prod_ri = b_real * tw_sin;
    wire signed [PROD_W-1:0] prod_ir = b_imag * tw_cos;

    wire signed [ACC_W-1:0] rr = {{(ACC_W-PROD_W){prod_rr[PROD_W-1]}}, prod_rr};
    wire signed [ACC_W-1:0] ii = {{(ACC_W-PROD_W){prod_ii[PROD_W-1]}}, prod_ii};
    wire signed [ACC_W-1:0] ri = {{(ACC_W-PROD_W){prod_ri[PROD_W-1]}}, prod_ri};
    wire signed [ACC_W-1:0] ir = {{(ACC_W-PROD_W){prod_ir[PROD_W-1]}}, prod_ir};

    wire signed [ACC_W-1:0] round_const = {{(ACC_W-15){1'b0}}, 15'sd16384};

    wire signed [ACC_W-1:0] rot_real_full = rr - ii + round_const;
    wire signed [ACC_W-1:0] rot_imag_full = ir + ri + round_const;

    wire signed [DATA_W-1:0] rot_real = rot_real_full >>> 15;
    wire signed [DATA_W-1:0] rot_imag = rot_imag_full >>> 15;

    assign y0_real = a_real + rot_real;
    assign y0_imag = a_imag + rot_imag;
    assign y1_real = a_real - rot_real;
    assign y1_imag = a_imag - rot_imag;

endmodule