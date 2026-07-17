`timescale 1ns/1ps

module fft16_butterfly #(
    parameter DATA_W  = 12,
    parameter COEFF_W = 16,
    parameter GAIN_W  = 4,
    parameter OUT_W   = DATA_W + GAIN_W
) (
    input  wire                         mode,      // 0: FFT, 1: IFFT
    input  wire signed [OUT_W-1:0]      xp_real,
    input  wire signed [OUT_W-1:0]      xp_imag,
    input  wire signed [OUT_W-1:0]      xq_real,
    input  wire signed [OUT_W-1:0]      xq_imag,
    input  wire signed [COEFF_W-1:0]    tw_cos,
    input  wire signed [COEFF_W-1:0]    tw_sin,

    output reg  signed [OUT_W-1:0]      yp_real,
    output reg  signed [OUT_W-1:0]      yp_imag,
    output reg  signed [OUT_W-1:0]      yq_real,
    output reg  signed [OUT_W-1:0]      yq_imag
);

    localparam EXT_COEFF_W = COEFF_W + 1;
    localparam PROD_W      = OUT_W + EXT_COEFF_W;
    localparam ACC_W       = PROD_W + 1;

    wire signed [EXT_COEFF_W-1:0] cos_ext;
    wire signed [EXT_COEFF_W-1:0] sin_ext;
    wire signed [EXT_COEFF_W-1:0] sin_eff;

    wire signed [PROD_W-1:0] rr_prod;
    wire signed [PROD_W-1:0] ii_prod;
    wire signed [PROD_W-1:0] ic_prod;
    wire signed [PROD_W-1:0] rs_prod;

    wire signed [ACC_W-1:0] real_acc;
    wire signed [ACC_W-1:0] imag_acc;

    wire signed [OUT_W-1:0] tr_real;
    wire signed [OUT_W-1:0] tr_imag;

    assign cos_ext = {tw_cos[COEFF_W-1], tw_cos};
    assign sin_ext = {tw_sin[COEFF_W-1], tw_sin};

    // FFT uses cos - j*sin. IFFT uses the conjugate, cos + j*sin.
    assign sin_eff = mode ? -sin_ext : sin_ext;

    assign rr_prod = xq_real * cos_ext;
    assign ii_prod = xq_imag * sin_eff;
    assign ic_prod = xq_imag * cos_ext;
    assign rs_prod = xq_real * sin_eff;

    assign real_acc = rr_prod + ii_prod + {{(ACC_W-15){1'b0}}, 15'sd16384};
    assign imag_acc = ic_prod - rs_prod + {{(ACC_W-15){1'b0}}, 15'sd16384};

    assign tr_real = real_acc >>> 15;
    assign tr_imag = imag_acc >>> 15;

    always @* begin
        yp_real = xp_real + tr_real;
        yp_imag = xp_imag + tr_imag;
        yq_real = xp_real - tr_real;
        yq_imag = xp_imag - tr_imag;
    end

endmodule