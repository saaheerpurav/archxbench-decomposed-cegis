`timescale 1ns/1ps

module fp_align #(
    parameter integer EXP_WIDTH  = 8,
    parameter integer MANT_WIDTH = 23
)(
    input  wire                  sign_a,
    input  wire                  sign_b,
    input  wire [EXP_WIDTH-1:0]  exp_a,
    input  wire [EXP_WIDTH-1:0]  exp_b,
    input  wire [MANT_WIDTH-1:0] frac_a,
    input  wire [MANT_WIDTH-1:0] frac_b,

    output reg                   aligned_sign_big,
    output reg                   aligned_sign_small,
    output reg  [EXP_WIDTH-1:0]  aligned_exp,
    output reg  [MANT_WIDTH+3:0] aligned_big,
    output reg  [MANT_WIDTH+3:0] aligned_small
);

    localparam integer EXT_WIDTH = MANT_WIDTH + 4;

    reg [EXT_WIDTH-1:0] mant_a;
    reg [EXT_WIDTH-1:0] mant_b;
    reg [EXT_WIDTH-1:0] mant_big;
    reg [EXT_WIDTH-1:0] mant_small;

    reg [EXP_WIDTH-1:0] exp_a_eff;
    reg [EXP_WIDTH-1:0] exp_b_eff;
    reg [EXP_WIDTH-1:0] exp_big;
    reg [EXP_WIDTH-1:0] exp_small;

    reg sign_big;
    reg sign_small;

    integer diff;
    integer i;
    reg sticky;

    always @* begin
        mant_a = {(exp_a != {EXP_WIDTH{1'b0}}), frac_a, 3'b000};
        mant_b = {(exp_b != {EXP_WIDTH{1'b0}}), frac_b, 3'b000};

        exp_a_eff = (exp_a == {EXP_WIDTH{1'b0}})
                  ? {{(EXP_WIDTH-1){1'b0}}, 1'b1}
                  : exp_a;
        exp_b_eff = (exp_b == {EXP_WIDTH{1'b0}})
                  ? {{(EXP_WIDTH-1){1'b0}}, 1'b1}
                  : exp_b;

        if ((exp_a_eff > exp_b_eff) ||
            ((exp_a_eff == exp_b_eff) && (mant_a >= mant_b))) begin
            mant_big   = mant_a;
            mant_small = mant_b;
            exp_big    = exp_a_eff;
            exp_small  = exp_b_eff;
            sign_big   = sign_a;
            sign_small = sign_b;
        end else begin
            mant_big   = mant_b;
            mant_small = mant_a;
            exp_big    = exp_b_eff;
            exp_small  = exp_a_eff;
            sign_big   = sign_b;
            sign_small = sign_a;
        end

        diff = exp_big - exp_small;

        aligned_big   = mant_big;
        aligned_small = mant_small;
        sticky        = 1'b0;

        if (diff >= EXT_WIDTH) begin
            aligned_small = {{(EXT_WIDTH-1){1'b0}}, |mant_small};
        end else if (diff > 0) begin
            for (i = 0; i < EXT_WIDTH; i = i + 1) begin
                if ((i < diff) && mant_small[i]) begin
                    sticky = 1'b1;
                end
            end

            aligned_small    = mant_small >> diff;
            aligned_small[0] = aligned_small[0] | sticky;
        end

        aligned_exp        = exp_big;
        aligned_sign_big   = sign_big;
        aligned_sign_small = sign_small;
    end

endmodule