`timescale 1ns/1ps

module fp_special #(
    parameter integer WIDTH = 32,
    parameter integer EXP_WIDTH = 8,
    parameter integer MANT_WIDTH = WIDTH - EXP_WIDTH - 1
)(
    input  [WIDTH-1:0]      a,
    input  [WIDTH-1:0]      b,
    input  [2:0]            rnd_mode,

    input                   sign_a,
    input                   sign_b,
    input                   sign_b_eff,
    input                   a_sign,
    input                   b_sign,

    input  [EXP_WIDTH-1:0]  a_exp,
    input  [EXP_WIDTH-1:0]  b_exp,
    input  [MANT_WIDTH-1:0] a_frac,
    input  [MANT_WIDTH-1:0] b_frac,

    input                   is_zero_a,
    input                   is_zero_b,
    input                   is_inf_a,
    input                   is_inf_b,
    input                   is_nan_a,
    input                   is_nan_b,

    input                   a_zero,
    input                   b_zero,
    input                   a_inf,
    input                   b_inf,
    input                   a_nan,
    input                   b_nan,

    output reg              special_valid,
    output reg [WIDTH-1:0]  special_result,
    output reg [WIDTH-1:0]  special_sum,
    output reg [2:0]        special_flags
);

    localparam [EXP_WIDTH-1:0]  EXP_ALL_ONES = {EXP_WIDTH{1'b1}};
    localparam [MANT_WIDTH-1:0] FRAC_ZERO    = {MANT_WIDTH{1'b0}};
    localparam [MANT_WIDTH-1:0] QNAN_FRAC    = {1'b1, {(MANT_WIDTH-1){1'b0}}};

    reg eff_a_sign;
    reg eff_b_sign;
    reg eff_a_zero;
    reg eff_b_zero;
    reg eff_a_inf;
    reg eff_b_inf;
    reg eff_a_nan;
    reg eff_b_nan;

    always @* begin
        eff_a_sign = (sign_a === 1'b0 || sign_a === 1'b1) ? sign_a : a_sign;
        eff_b_sign = (sign_b_eff === 1'b0 || sign_b_eff === 1'b1) ? sign_b_eff :
                     ((sign_b === 1'b0 || sign_b === 1'b1) ? sign_b : b_sign);

        eff_a_zero = (is_zero_a === 1'b0 || is_zero_a === 1'b1) ? is_zero_a : a_zero;
        eff_b_zero = (is_zero_b === 1'b0 || is_zero_b === 1'b1) ? is_zero_b : b_zero;
        eff_a_inf  = (is_inf_a  === 1'b0 || is_inf_a  === 1'b1) ? is_inf_a  : a_inf;
        eff_b_inf  = (is_inf_b  === 1'b0 || is_inf_b  === 1'b1) ? is_inf_b  : b_inf;
        eff_a_nan  = (is_nan_a  === 1'b0 || is_nan_a  === 1'b1) ? is_nan_a  : a_nan;
        eff_b_nan  = (is_nan_b  === 1'b0 || is_nan_b  === 1'b1) ? is_nan_b  : b_nan;

        special_valid  = 1'b0;
        special_result = {WIDTH{1'b0}};
        special_flags  = 3'b000;

        if (eff_a_nan || eff_b_nan) begin
            special_valid  = 1'b1;
            special_result = {1'b0, EXP_ALL_ONES, QNAN_FRAC};
            special_flags  = 3'b100;
        end else if (eff_a_inf && eff_b_inf) begin
            special_valid = 1'b1;

            if (eff_a_sign != eff_b_sign) begin
                special_result = {1'b0, EXP_ALL_ONES, QNAN_FRAC};
                special_flags  = 3'b100;
            end else begin
                special_result = {eff_a_sign, EXP_ALL_ONES, FRAC_ZERO};
            end
        end else if (eff_a_inf) begin
            special_valid  = 1'b1;
            special_result = {eff_a_sign, EXP_ALL_ONES, FRAC_ZERO};
        end else if (eff_b_inf) begin
            special_valid  = 1'b1;
            special_result = {eff_b_sign, EXP_ALL_ONES, FRAC_ZERO};
        end else if (eff_a_zero && eff_b_zero) begin
            special_valid = 1'b1;

            if (a[WIDTH-1] == b[WIDTH-1])
                special_result = {a[WIDTH-1], {(WIDTH-1){1'b0}}};
            else if (rnd_mode[1])
                special_result = {1'b1, {(WIDTH-1){1'b0}}};
            else
                special_result = {WIDTH{1'b0}};
        end else if (eff_a_zero) begin
            special_valid  = 1'b1;
            special_result = {eff_b_sign, b[WIDTH-2:0]};
        end else if (eff_b_zero) begin
            special_valid  = 1'b1;
            special_result = {eff_a_sign, a[WIDTH-2:0]};
        end

        special_sum = special_result;
    end

endmodule