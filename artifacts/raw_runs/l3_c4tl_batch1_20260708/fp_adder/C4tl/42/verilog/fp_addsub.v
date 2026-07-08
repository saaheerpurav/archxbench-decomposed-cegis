`timescale 1ns/1ps

module fp_addsub #(
    parameter integer EXP_WIDTH  = 8,
    parameter integer MANT_WIDTH = 23
)(
    input  wire                   big_sign,
    input  wire                   small_sign,
    input  wire [EXP_WIDTH:0]     common_exp,
    input  wire [MANT_WIDTH+3:0]  big_sig,
    input  wire [MANT_WIDTH+3:0]  small_sig,
    output reg                    raw_sign,
    output reg  [EXP_WIDTH:0]     raw_exp,
    output reg  [MANT_WIDTH+4:0]  raw_sig,
    output reg                    raw_zero
);

    always @* begin
        raw_exp = common_exp;

        if (big_sign == small_sign) begin
            raw_sig = {1'b0, big_sig} + {1'b0, small_sig};
        end else begin
            raw_sig = {1'b0, big_sig} - {1'b0, small_sig};
        end

        raw_zero = (raw_sig == {MANT_WIDTH+5{1'b0}});
        raw_sign = raw_zero ? 1'b0 : big_sign;
    end

endmodule