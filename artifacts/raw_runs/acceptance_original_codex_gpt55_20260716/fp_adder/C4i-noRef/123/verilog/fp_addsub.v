`timescale 1ns/1ps

module fp_addsub #(
    parameter integer EXP_WIDTH  = 8,
    parameter integer MANT_WIDTH = 23
)(
    input  [EXP_WIDTH:0]     align_exp,
    input                    sign_large,
    input                    sign_small,
    input  [MANT_WIDTH+3:0]  large_sig,
    input  [MANT_WIDTH+3:0]  small_sig,
    output reg               result_sign,
    output reg               result_zero,
    output reg [EXP_WIDTH:0] result_exp,
    output reg [MANT_WIDTH+4:0] result_sig
);

    always @* begin
        result_exp = align_exp;

        if (sign_large == sign_small) begin
            result_sig = {1'b0, large_sig} + {1'b0, small_sig};
        end else begin
            result_sig = {1'b0, large_sig} - {1'b0, small_sig};
        end

        result_zero = (result_sig == {MANT_WIDTH+5{1'b0}});
        result_sign = result_zero ? 1'b0 : sign_large;
    end

endmodule