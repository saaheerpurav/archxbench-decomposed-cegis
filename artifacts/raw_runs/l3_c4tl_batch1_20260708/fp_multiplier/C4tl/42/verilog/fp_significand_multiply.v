`timescale 1ns/1ps

module fp_significand_multiply #(
    parameter EXP_WIDTH  = 8,
    parameter MANT_WIDTH = 23
)(
    input  [EXP_WIDTH-1:0] exp_a,
    input  [EXP_WIDTH-1:0] exp_b,
    input  [MANT_WIDTH-1:0] mant_a,
    input  [MANT_WIDTH-1:0] mant_b,

    output [MANT_WIDTH:0] sig_a,
    output [MANT_WIDTH:0] sig_b,
    output signed [EXP_WIDTH+1:0] exp_sum,
    output [(2*(MANT_WIDTH+1))-1:0] sig_product
);

    localparam signed [EXP_WIDTH+1:0] BIAS =
        (1 << (EXP_WIDTH-1)) - 1;

    wire exp_a_is_zero;
    wire exp_b_is_zero;

    wire [EXP_WIDTH:0] exp_a_eff;
    wire [EXP_WIDTH:0] exp_b_eff;

    assign exp_a_is_zero = (exp_a == {EXP_WIDTH{1'b0}});
    assign exp_b_is_zero = (exp_b == {EXP_WIDTH{1'b0}});

    assign sig_a = exp_a_is_zero ? {1'b0, mant_a} : {1'b1, mant_a};
    assign sig_b = exp_b_is_zero ? {1'b0, mant_b} : {1'b1, mant_b};

    assign exp_a_eff = exp_a_is_zero ? {{EXP_WIDTH{1'b0}}, 1'b1}
                                      : {1'b0, exp_a};

    assign exp_b_eff = exp_b_is_zero ? {{EXP_WIDTH{1'b0}}, 1'b1}
                                      : {1'b0, exp_b};

    assign exp_sum =
        $signed({1'b0, exp_a_eff}) +
        $signed({1'b0, exp_b_eff}) -
        BIAS;

    assign sig_product = sig_a * sig_b;

endmodule