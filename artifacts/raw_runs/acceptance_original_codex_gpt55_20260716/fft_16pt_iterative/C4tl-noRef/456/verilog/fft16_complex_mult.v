`timescale 1ns/1ps

module fft16_complex_mult #(
    parameter DATA_W  = 12,
    parameter COEFF_W = 16,
    parameter GAIN_W  = 4
) (
    input  wire                            mode,      // 0: FFT, 1: IFFT
    input  wire signed [DATA_W+GAIN_W-1:0] in_real,
    input  wire signed [DATA_W+GAIN_W-1:0] in_imag,
    input  wire signed [COEFF_W-1:0]       cos_q15,
    input  wire signed [COEFF_W-1:0]       sin_q15,
    output wire signed [DATA_W+GAIN_W-1:0] out_real,
    output wire signed [DATA_W+GAIN_W-1:0] out_imag
);

    localparam OUT_W       = DATA_W + GAIN_W;
    localparam FRAC_W      = COEFF_W - 1;       // Q1.15 for COEFF_W=16
    localparam COEFF_EXT_W = COEFF_W + 1;       // allows exact negation
    localparam PROD_W      = OUT_W + COEFF_EXT_W;
    localparam ACC_W       = PROD_W + 1;

    wire signed [COEFF_EXT_W-1:0] cos_ext = {cos_q15[COEFF_W-1], cos_q15};
    wire signed [COEFF_EXT_W-1:0] sin_ext = {sin_q15[COEFF_W-1], sin_q15};

    // Datapath computes multiplication by (cos - j*sin_eff).
    // FFT:  sin_eff = +sin -> cos - j*sin
    // IFFT: sin_eff = -sin -> cos + j*sin
    wire signed [COEFF_EXT_W-1:0] sin_eff = mode ? -sin_ext : sin_ext;

    wire signed [PROD_W-1:0] xr_cos = in_real * cos_ext;
    wire signed [PROD_W-1:0] xi_sin = in_imag * sin_eff;
    wire signed [PROD_W-1:0] xi_cos = in_imag * cos_ext;
    wire signed [PROD_W-1:0] xr_sin = in_real * sin_eff;

    wire signed [ACC_W-1:0] real_full =
        {xr_cos[PROD_W-1], xr_cos} + {xi_sin[PROD_W-1], xi_sin};

    wire signed [ACC_W-1:0] imag_full =
        {xi_cos[PROD_W-1], xi_cos} - {xr_sin[PROD_W-1], xr_sin};

    wire signed [ACC_W-1:0] round_const =
        {{(ACC_W-1){1'b0}}, 1'b1} <<< (FRAC_W - 1);

    wire signed [ACC_W-1:0] real_rounded = (real_full + round_const) >>> FRAC_W;
    wire signed [ACC_W-1:0] imag_rounded = (imag_full + round_const) >>> FRAC_W;

    assign out_real = real_rounded[OUT_W-1:0];
    assign out_imag = imag_rounded[OUT_W-1:0];

endmodule