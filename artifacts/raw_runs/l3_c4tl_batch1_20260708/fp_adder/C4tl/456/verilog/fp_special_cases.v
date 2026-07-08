`timescale 1ns/1ps

module fp_special_cases #(
    parameter integer WIDTH = 32,
    parameter integer EXP_WIDTH = 8,
    parameter integer MANT_WIDTH = 23
)(
    input  [WIDTH-1:0] a,
    input  [WIDTH-1:0] b,
    input  [2:0] rnd_mode,
    input  sign_a,
    input  sign_b,
    input  a_zero,
    input  b_zero,
    input  a_inf,
    input  b_inf,
    input  a_nan,
    input  b_nan,
    output reg special_valid,
    output reg [WIDTH-1:0] special_result,
    output reg [2:0] special_flags
);

    localparam [EXP_WIDTH-1:0] EXP_ALL_ONES = {EXP_WIDTH{1'b1}};
    localparam [EXP_WIDTH-1:0] EXP_ZERO     = {EXP_WIDTH{1'b0}};
    localparam [MANT_WIDTH-1:0] MANT_ZERO   = {MANT_WIDTH{1'b0}};
    localparam [MANT_WIDTH-1:0] QUIET_NAN_FRAC =
        {1'b1, {(MANT_WIDTH-1){1'b0}}};

    always @* begin
        special_valid  = 1'b0;
        special_result = {WIDTH{1'b0}};
        special_flags  = 3'b000;

        if (a_nan || b_nan) begin
            special_valid  = 1'b1;
            special_result = {1'b0, EXP_ALL_ONES, QUIET_NAN_FRAC};
            special_flags  = 3'b100;
        end else if (a_inf && b_inf && (sign_a != sign_b)) begin
            special_valid  = 1'b1;
            special_result = {1'b0, EXP_ALL_ONES, QUIET_NAN_FRAC};
            special_flags  = 3'b100;
        end else if (a_inf) begin
            special_valid  = 1'b1;
            special_result = a;
            special_flags  = 3'b000;
        end else if (b_inf) begin
            special_valid  = 1'b1;
            special_result = b;
            special_flags  = 3'b000;
        end else if (a_zero && b_zero) begin
            special_valid  = 1'b1;
            special_result = {
                (rnd_mode == 3'd3) ? (sign_a | sign_b) : (sign_a & sign_b),
                EXP_ZERO,
                MANT_ZERO
            };
            special_flags  = 3'b000;
        end else if (a_zero) begin
            special_valid  = 1'b1;
            special_result = b;
            special_flags  = 3'b000;
        end else if (b_zero) begin
            special_valid  = 1'b1;
            special_result = a;
            special_flags  = 3'b000;
        end
    end

endmodule