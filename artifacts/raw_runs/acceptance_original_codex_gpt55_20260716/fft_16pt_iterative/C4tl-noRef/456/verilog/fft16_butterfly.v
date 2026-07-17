module fft16_butterfly #(
    parameter DATA_W  = 12,
    parameter COEFF_W = 16,
    parameter GAIN_W  = 4
) (
    input  mode, // 0: FFT, 1: IFFT

    input  signed [DATA_W+GAIN_W-1:0] a_real,
    input  signed [DATA_W+GAIN_W-1:0] a_imag,
    input  signed [DATA_W+GAIN_W-1:0] b_real,
    input  signed [DATA_W+GAIN_W-1:0] b_imag,

    input  signed [COEFF_W-1:0] tw_cos,
    input  signed [COEFF_W-1:0] tw_sin,

    output signed [DATA_W+GAIN_W-1:0] y0_real,
    output signed [DATA_W+GAIN_W-1:0] y0_imag,
    output signed [DATA_W+GAIN_W-1:0] y1_real,
    output signed [DATA_W+GAIN_W-1:0] y1_imag
);

    localparam OUT_W  = DATA_W + GAIN_W;
    localparam PROD_W = OUT_W + COEFF_W;
    localparam ACC_W  = PROD_W + 1;

    wire signed [COEFF_W-1:0] sin_eff;
    assign sin_eff = mode ? -tw_sin : tw_sin;

    wire signed [PROD_W-1:0] br_cos;
    wire signed [PROD_W-1:0] bi_sin;
    wire signed [PROD_W-1:0] bi_cos;
    wire signed [PROD_W-1:0] br_sin;

    assign br_cos = b_real * tw_cos;
    assign bi_sin = b_imag * sin_eff;
    assign bi_cos = b_imag * tw_cos;
    assign br_sin = b_real * sin_eff;

    wire signed [ACC_W-1:0] br_cos_ext;
    wire signed [ACC_W-1:0] bi_sin_ext;
    wire signed [ACC_W-1:0] bi_cos_ext;
    wire signed [ACC_W-1:0] br_sin_ext;

    assign br_cos_ext = {{(ACC_W-PROD_W){br_cos[PROD_W-1]}}, br_cos};
    assign bi_sin_ext = {{(ACC_W-PROD_W){bi_sin[PROD_W-1]}}, bi_sin};
    assign bi_cos_ext = {{(ACC_W-PROD_W){bi_cos[PROD_W-1]}}, bi_cos};
    assign br_sin_ext = {{(ACC_W-PROD_W){br_sin[PROD_W-1]}}, br_sin};

    wire signed [ACC_W-1:0] round_q15;
    assign round_q15 = $signed(ACC_W'sd16384);

    wire signed [ACC_W-1:0] rot_real_acc;
    wire signed [ACC_W-1:0] rot_imag_acc;

    assign rot_real_acc = br_cos_ext + bi_sin_ext + round_q15;
    assign rot_imag_acc = bi_cos_ext - br_sin_ext + round_q15;

    wire signed [OUT_W-1:0] rot_real;
    wire signed [OUT_W-1:0] rot_imag;

    assign rot_real = rot_real_acc >>> 15;
    assign rot_imag = rot_imag_acc >>> 15;

    assign y0_real = a_real + rot_real;
    assign y0_imag = a_imag + rot_imag;
    assign y1_real = a_real - rot_real;
    assign y1_imag = a_imag - rot_imag;

endmodule