`timescale 1ns/1ps

module fp_special_cases #(
    parameter EXP_WIDTH  = 8,
    parameter MANT_WIDTH = 23,
    parameter WIDTH      = 1 + EXP_WIDTH + MANT_WIDTH
)(
    input sign_a,
    input sign_b,
    input [MANT_WIDTH-1:0] mant_a,
    input [MANT_WIDTH-1:0] mant_b,
    input a_zero,
    input b_zero,
    input a_inf,
    input b_inf,
    input a_nan,
    input b_nan,
    output result_sign,
    output reg special_valid,
    output reg [WIDTH-1:0] special_product,
    output reg [2:0] special_flags
);

    localparam [EXP_WIDTH-1:0]  EXP_ALL_ONES = {EXP_WIDTH{1'b1}};
    localparam [EXP_WIDTH-1:0]  EXP_ZERO     = {EXP_WIDTH{1'b0}};
    localparam [MANT_WIDTH-1:0] MANT_ZERO    = {MANT_WIDTH{1'b0}};
    localparam [MANT_WIDTH-1:0] QNAN_MANT    = {1'b1, {(MANT_WIDTH-1){1'b0}}};

    assign result_sign = sign_a ^ sign_b;

    always @(*) begin
        special_valid   = 1'b0;
        special_product = {WIDTH{1'b0}};
        special_flags   = 3'b000;

        if (a_nan || b_nan) begin
            special_valid   = 1'b1;
            special_product = {1'b0, EXP_ALL_ONES, QNAN_MANT};
            special_flags   = 3'b100;
        end else if ((a_inf && b_zero) || (b_inf && a_zero)) begin
            special_valid   = 1'b1;
            special_product = {1'b0, EXP_ALL_ONES, QNAN_MANT};
            special_flags   = 3'b100;
        end else if (a_inf || b_inf) begin
            special_valid   = 1'b1;
            special_product = {result_sign, EXP_ALL_ONES, MANT_ZERO};
            special_flags   = 3'b010;
        end else if (a_zero || b_zero) begin
            special_valid   = 1'b1;
            special_product = {result_sign, EXP_ZERO, MANT_ZERO};
            special_flags   = 3'b001;
        end
    end

endmodule