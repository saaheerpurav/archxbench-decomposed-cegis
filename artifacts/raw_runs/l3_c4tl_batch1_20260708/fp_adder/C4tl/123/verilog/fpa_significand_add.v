`timescale 1ns/1ps

module fpa_significand_add #(
    parameter integer EXP_WIDTH  = 8,
    parameter integer MANT_WIDTH = 23
)(
    input  wire                    sign_big,
    input  wire                    sign_small,
    input  wire [EXP_WIDTH:0]      exp_big,
    input  wire [MANT_WIDTH+3:0]   sig_big,
    input  wire [MANT_WIDTH+3:0]   sig_small,
    input  wire [2:0]              rnd_mode,
    output reg                     raw_sign,
    output reg  [EXP_WIDTH:0]      raw_exp,
    output reg  [MANT_WIDTH+4:0]   raw_sig,
    output reg                     raw_zero,
    output wire                    op_sub
);

    wire [MANT_WIDTH+4:0] sig_big_ext;
    wire [MANT_WIDTH+4:0] sig_small_ext;
    wire [MANT_WIDTH+4:0] add_result;
    wire [MANT_WIDTH+4:0] sub_result;

    assign op_sub        = (sign_big != sign_small);
    assign sig_big_ext   = {1'b0, sig_big};
    assign sig_small_ext = {1'b0, sig_small};
    assign add_result    = sig_big_ext + sig_small_ext;
    assign sub_result    = sig_big_ext - sig_small_ext;

    always @* begin
        raw_exp  = exp_big;
        raw_sig  = {MANT_WIDTH+5{1'b0}};
        raw_sign = sign_big;
        raw_zero = 1'b0;

        if (!op_sub) begin
            raw_sig  = add_result;
            raw_sign = sign_big;
            raw_zero = (add_result == {MANT_WIDTH+5{1'b0}});
        end else begin
            raw_sig = sub_result;

            if (sub_result == {MANT_WIDTH+5{1'b0}}) begin
                raw_zero = 1'b1;
                raw_sign = (rnd_mode == 3'd3);
            end else begin
                raw_zero = 1'b0;
                raw_sign = sign_big;
            end
        end
    end

endmodule