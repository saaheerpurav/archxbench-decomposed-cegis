`timescale 1ns/1ps

module fp_special_cases #(
    parameter WIDTH = 32,
    parameter EXP_WIDTH = 8,
    parameter MANT_WIDTH = 23
)(
    input  [WIDTH-1:0] a,
    input  [WIDTH-1:0] b,
    input  [2:0]       rnd_mode,

    input              sign_a,
    input              sign_b,

    input              zero_a,
    input              zero_b,
    input              inf_a,
    input              inf_b,
    input              nan_a,
    input              nan_b,

    output reg         special_valid,
    output reg [WIDTH-1:0] special_sum,
    output reg [2:0]   special_flags
);

    localparam [EXP_WIDTH-1:0] EXP_ALL_ONES = {EXP_WIDTH{1'b1}};
    localparam [EXP_WIDTH-1:0] EXP_ZERO     = {EXP_WIDTH{1'b0}};
    localparam [MANT_WIDTH-1:0] MANT_ZERO   = {MANT_WIDTH{1'b0}};
    localparam [MANT_WIDTH-1:0] QNAN_MANT   = {1'b1, {(MANT_WIDTH-1){1'b0}}};

    localparam [2:0] FLAG_NONE    = 3'b000;
    localparam [2:0] FLAG_INVALID = 3'b100;

    localparam [2:0] RND_TOWARD_NEG = 3'b011;

    wire [WIDTH-1:0] canonical_qnan;
    wire zero_sign;

    assign canonical_qnan = {1'b0, EXP_ALL_ONES, QNAN_MANT};

    assign zero_sign = (rnd_mode == RND_TOWARD_NEG) ? (sign_a | sign_b) :
                                                      (sign_a & sign_b);

    always @(*) begin
        special_valid = 1'b0;
        special_sum   = {WIDTH{1'b0}};
        special_flags = FLAG_NONE;

        if (nan_a || nan_b) begin
            special_valid = 1'b1;
            special_sum   = canonical_qnan;
            special_flags = FLAG_INVALID;
        end else if (inf_a && inf_b && (sign_a != sign_b)) begin
            special_valid = 1'b1;
            special_sum   = canonical_qnan;
            special_flags = FLAG_INVALID;
        end else if (inf_a) begin
            special_valid = 1'b1;
            special_sum   = {sign_a, EXP_ALL_ONES, MANT_ZERO};
            special_flags = FLAG_NONE;
        end else if (inf_b) begin
            special_valid = 1'b1;
            special_sum   = {sign_b, EXP_ALL_ONES, MANT_ZERO};
            special_flags = FLAG_NONE;
        end else if (zero_a && zero_b) begin
            special_valid = 1'b1;
            special_sum   = {zero_sign, EXP_ZERO, MANT_ZERO};
            special_flags = FLAG_NONE;
        end else if (zero_a) begin
            special_valid = 1'b1;
            special_sum   = b;
            special_flags = FLAG_NONE;
        end else if (zero_b) begin
            special_valid = 1'b1;
            special_sum   = a;
            special_flags = FLAG_NONE;
        end
    end

endmodule