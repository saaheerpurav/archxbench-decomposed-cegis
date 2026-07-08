`timescale 1ns/1ps

module fp_addsub #(
    parameter integer EXP_WIDTH  = 8,
    parameter integer MANT_WIDTH = 23
)(
    input  wire                  sign_big,
    input  wire                  sign_small,
    input  wire [EXP_WIDTH-1:0]  aligned_exp,
    input  wire [MANT_WIDTH+3:0] mant_big,
    input  wire [MANT_WIDTH+3:0] mant_small,
    output reg                   raw_sign,
    output reg  [EXP_WIDTH-1:0]  raw_exp,
    output reg  [MANT_WIDTH+4:0] raw_sum,
    output reg                   raw_zero
);

    always @* begin
        raw_exp = aligned_exp;

        if (sign_big == sign_small) begin
            raw_sum  = {1'b0, mant_big} + {1'b0, mant_small};
            raw_sign = sign_big;
        end else begin
            raw_sum  = {1'b0, mant_big} - {1'b0, mant_small};
            raw_sign = sign_big;
        end

        raw_zero = (raw_sum == {MANT_WIDTH+5{1'b0}});

        if (raw_zero) begin
            raw_sign = 1'b0;
        end
    end

endmodule