`timescale 1ns/1ps

module fpa_special_cases #(
    parameter integer WIDTH = 32,
    parameter integer EXP_WIDTH = 8,
    parameter integer MANT_WIDTH = 23
)(
    input  [WIDTH-1:0] a,
    input  [WIDTH-1:0] b,
    input              sign_a,
    input              sign_b,
    input              zero_a,
    input              zero_b,
    input              inf_a,
    input              inf_b,
    input              nan_a,
    input              nan_b,
    input  [2:0]       rnd_mode,
    output reg         special_valid,
    output reg [WIDTH-1:0] special_sum,
    output reg [2:0]   special_flags
);

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

        if (nan_a || nan_b) begin
            special_valid = 1'b1;
            special_sum   = quiet_nan;
            special_flags = 3'b100;
        end else if (inf_a && inf_b && (sign_a != sign_b)) begin
            special_valid = 1'b1;
            special_sum   = quiet_nan;
            special_flags = 3'b100;
        end else if (inf_a) begin
            special_valid = 1'b1;
            special_sum   = {sign_a, {EXP_WIDTH{1'b1}}, {MANT_WIDTH{1'b0}}};
            special_flags = 3'b000;
        end else if (inf_b) begin
            special_valid = 1'b1;
            special_sum   = {sign_b, {EXP_WIDTH{1'b1}}, {MANT_WIDTH{1'b0}}};
            special_flags = 3'b000;
        end else if (zero_a && zero_b) begin
            special_valid = 1'b1;

            if (sign_a == sign_b)
                zero_sign = sign_a;
            else
                zero_sign = (rnd_mode == 3'd3);

            special_sum   = {zero_sign, {(WIDTH-1){1'b0}}};
            special_flags = 3'b000;
        end else if (zero_a) begin
            special_valid = 1'b1;
            special_sum   = b;
            special_flags = 3'b000;
        end else if (zero_b) begin
            special_valid = 1'b1;
            special_sum   = a;
            special_flags = 3'b000;
        end
    end

endmodule