`timescale 1ns/1ps

module ifft16_complex_mult #(
    parameter DATA_W  = 16,
    parameter COEFF_W = 16
) (
    input  signed [DATA_W-1:0]  a_real,
    input  signed [DATA_W-1:0]  a_imag,
    input  signed [COEFF_W-1:0] tw_cos,
    input  signed [COEFF_W-1:0] tw_sin,
    output signed [DATA_W-1:0]  y_real,
    output signed [DATA_W-1:0]  y_imag
);
    localparam integer FRAC_W  = 15;
    localparam integer PROD_W  = DATA_W + COEFF_W;
    localparam integer ACC_W   = PROD_W + 1;

    wire signed [PROD_W-1:0] rr_prod = a_real * tw_cos;
    wire signed [PROD_W-1:0] ii_prod = a_imag * tw_sin;
    wire signed [PROD_W-1:0] ri_prod = a_real * tw_sin;
    wire signed [PROD_W-1:0] ir_prod = a_imag * tw_cos;

    wire signed [ACC_W-1:0] real_acc =
        {rr_prod[PROD_W-1], rr_prod} - {ii_prod[PROD_W-1], ii_prod};

    wire signed [ACC_W-1:0] imag_acc =
        {ri_prod[PROD_W-1], ri_prod} + {ir_prod[PROD_W-1], ir_prod};

    wire signed [ACC_W-1:0] real_rounded =
        real_acc + {{(ACC_W-FRAC_W){1'b0}}, 1'b1, {(FRAC_W-1){1'b0}}};

    wire signed [ACC_W-1:0] imag_rounded =
        imag_acc + {{(ACC_W-FRAC_W){1'b0}}, 1'b1, {(FRAC_W-1){1'b0}}};

    assign y_real = real_rounded >>> FRAC_W;
    assign y_imag = imag_rounded >>> FRAC_W;

endmodule