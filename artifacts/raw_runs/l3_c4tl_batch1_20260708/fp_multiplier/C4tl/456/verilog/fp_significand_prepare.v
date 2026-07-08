`timescale 1ns/1ps

module fp_significand_prepare #(
    parameter EXP_WIDTH  = 8,
    parameter MANT_WIDTH = 23
)(
    input  [EXP_WIDTH-1:0]  exp_a,
    input  [EXP_WIDTH-1:0]  exp_b,
    input  [MANT_WIDTH-1:0] mant_a,
    input  [MANT_WIDTH-1:0] mant_b,
    input                   a_is_denorm,
    input                   b_is_denorm,
    output [MANT_WIDTH:0]   sig_a,
    output [MANT_WIDTH:0]   sig_b,
    output signed [EXP_WIDTH+1:0] base_exp
);

    localparam integer BIAS_INT = (1 << (EXP_WIDTH - 1)) - 1;
    localparam signed [EXP_WIDTH+1:0] BIAS =
        BIAS_INT[EXP_WIDTH+1:0];

    wire [EXP_WIDTH-1:0] effective_exp_a;
    wire [EXP_WIDTH-1:0] effective_exp_b;

    wire signed [EXP_WIDTH+1:0] exp_a_ext;
    wire signed [EXP_WIDTH+1:0] exp_b_ext;

    assign effective_exp_a = a_is_denorm ?
                             {{(EXP_WIDTH-1){1'b0}}, 1'b1} :
                             exp_a;

    assign effective_exp_b = b_is_denorm ?
                             {{(EXP_WIDTH-1){1'b0}}, 1'b1} :
                             exp_b;

    assign sig_a = a_is_denorm ? {1'b0, mant_a} : {1'b1, mant_a};
    assign sig_b = b_is_denorm ? {1'b0, mant_b} : {1'b1, mant_b};

    assign exp_a_ext = $signed({2'b00, effective_exp_a});
    assign exp_b_ext = $signed({2'b00, effective_exp_b});

    assign base_exp = exp_a_ext + exp_b_ext - BIAS;

endmodule