`timescale 1ns/1ps

module fp_significand_multiply #(
    parameter EXP_WIDTH  = 8,
    parameter MANT_WIDTH = 23
)(
    input  sign_a,
    input  sign_b,
    input  [EXP_WIDTH-1:0]  exp_a,
    input  [EXP_WIDTH-1:0]  exp_b,
    input  [MANT_WIDTH-1:0] mant_a,
    input  [MANT_WIDTH-1:0] mant_b,
    input  a_is_denorm,
    input  b_is_denorm,
    input  a_is_zero,
    input  b_is_zero,
    output result_sign,
    output signed [EXP_WIDTH+2:0] raw_exp,
    output [((MANT_WIDTH+1)*2)-1:0] sig_product,
    output mult_zero
);

    localparam SIG_WIDTH = MANT_WIDTH + 1;
    localparam PROD_WIDTH = SIG_WIDTH * 2;
    localparam signed [EXP_WIDTH+2:0] BIAS =
        (1 << (EXP_WIDTH - 1)) - 1;

    wire [SIG_WIDTH-1:0] sig_a;
    wire [SIG_WIDTH-1:0] sig_b;

    wire [EXP_WIDTH-1:0] eff_exp_a;
    wire [EXP_WIDTH-1:0] eff_exp_b;

    wire signed [EXP_WIDTH+2:0] signed_eff_exp_a;
    wire signed [EXP_WIDTH+2:0] signed_eff_exp_b;

    assign result_sign = sign_a ^ sign_b;

    assign sig_a = (a_is_denorm || a_is_zero) ? {1'b0, mant_a}
                                               : {1'b1, mant_a};
    assign sig_b = (b_is_denorm || b_is_zero) ? {1'b0, mant_b}
                                               : {1'b1, mant_b};

    assign eff_exp_a = (a_is_denorm || a_is_zero) ? {{(EXP_WIDTH-1){1'b0}}, 1'b1}
                                                  : exp_a;
    assign eff_exp_b = (b_is_denorm || b_is_zero) ? {{(EXP_WIDTH-1){1'b0}}, 1'b1}
                                                  : exp_b;

    assign signed_eff_exp_a = $signed({3'b000, eff_exp_a});
    assign signed_eff_exp_b = $signed({3'b000, eff_exp_b});

    assign raw_exp = signed_eff_exp_a + signed_eff_exp_b - BIAS;

    assign sig_product = sig_a * sig_b;

    assign mult_zero = a_is_zero || b_is_zero ||
                       (sig_product == {PROD_WIDTH{1'b0}});

endmodule