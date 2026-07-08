`timescale 1ns/1ps

module fpa_special_cases #(
    parameter integer WIDTH = 32,
    parameter integer EXP_WIDTH = 8,
    parameter integer MANT_WIDTH = 23
)(
    input  [WIDTH-1:0] a,
    input  [WIDTH-1:0] b,
    input  [2:0]       rnd_mode,
    output reg         special_valid,
    output reg [WIDTH-1:0] special_sum,
    output reg [2:0]   special_flags
);

    wire sign_a = a[WIDTH-1];
    wire sign_b = b[WIDTH-1];

    wire [EXP_WIDTH-1:0]  exp_a  = a[MANT_WIDTH +: EXP_WIDTH];
    wire [EXP_WIDTH-1:0]  exp_b  = b[MANT_WIDTH +: EXP_WIDTH];
    wire [MANT_WIDTH-1:0] frac_a = a[MANT_WIDTH-1:0];
    wire [MANT_WIDTH-1:0] frac_b = b[MANT_WIDTH-1:0];

    wire exp_a_zero = (exp_a == {EXP_WIDTH{1'b0}});
    wire exp_b_zero = (exp_b == {EXP_WIDTH{1'b0}});
    wire exp_a_ones = (exp_a == {EXP_WIDTH{1'b1}});
    wire exp_b_ones = (exp_b == {EXP_WIDTH{1'b1}});

    wire frac_a_zero = (frac_a == {MANT_WIDTH{1'b0}});
    wire frac_b_zero = (frac_b == {MANT_WIDTH{1'b0}});

    wire a_zero = exp_a_zero && frac_a_zero;
    wire b_zero = exp_b_zero && frac_b_zero;
    wire a_inf  = exp_a_ones && frac_a_zero;
    wire b_inf  = exp_b_ones && frac_b_zero;
    wire a_nan  = exp_a_ones && !frac_a_zero;
    wire b_nan  = exp_b_ones && !frac_b_zero;

    wire [WIDTH-1:0] quiet_nan = {
        1'b0,
        {EXP_WIDTH{1'b1}},
        1'b1,
        {(MANT_WIDTH-1){1'b0}}
    };

    reg zero_sign;

    always @* begin
        special_valid = 1'b0;
        special_sum   = {WIDTH{1'b0}};
        special_flags = 3'b000;
        zero_sign     = 1'b0;

        if (a_nan || b_nan) begin
            special_valid = 1'b1;
            special_sum   = quiet_nan;
            special_flags = 3'b100;
        end else if (a_inf && b_inf && (sign_a != sign_b)) begin
            special_valid = 1'b1;
            special_sum   = quiet_nan;
            special_flags = 3'b100;
        end else if (a_inf) begin
            special_valid = 1'b1;
            special_sum   = a;
            special_flags = 3'b000;
        end else if (b_inf) begin
            special_valid = 1'b1;
            special_sum   = b;
            special_flags = 3'b000;
        end else if (a_zero && b_zero) begin
            special_valid = 1'b1;

            if (sign_a && sign_b)
                zero_sign = 1'b1;
            else if (sign_a != sign_b)
                zero_sign = (rnd_mode == 3'd3);
            else
                zero_sign = 1'b0;

            special_sum   = {zero_sign, {(WIDTH-1){1'b0}}};
            special_flags = 3'b000;
        end else if (a_zero) begin
            special_valid = 1'b1;
            special_sum   = b;
            special_flags = 3'b000;
        end else if (b_zero) begin
            special_valid = 1'b1;
            special_sum   = a;
            special_flags = 3'b000;
        end
    end

endmodule