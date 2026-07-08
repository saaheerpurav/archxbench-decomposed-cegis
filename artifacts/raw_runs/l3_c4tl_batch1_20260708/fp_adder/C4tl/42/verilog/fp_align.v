`timescale 1ns/1ps

module fp_align #(
    parameter integer EXP_WIDTH  = 8,
    parameter integer MANT_WIDTH = 23
)(
    input  wire                    a_sign,
    input  wire                    b_sign,
    input  wire [EXP_WIDTH-1:0]    a_exp,
    input  wire [EXP_WIDTH-1:0]    b_exp,
    input  wire [MANT_WIDTH-1:0]   a_mant,
    input  wire [MANT_WIDTH-1:0]   b_mant,
    input  wire                    a_denorm,
    input  wire                    b_denorm,
    output reg                     big_sign,
    output reg                     small_sign,
    output reg  [EXP_WIDTH:0]      common_exp,
    output reg  [MANT_WIDTH+3:0]   big_sig,
    output reg  [MANT_WIDTH+3:0]   small_sig,
    output wire                    any_denorm
);

    localparam integer SIG_WIDTH = MANT_WIDTH + 4;

    reg [EXP_WIDTH:0]    a_eff_exp;
    reg [EXP_WIDTH:0]    b_eff_exp;
    reg [EXP_WIDTH:0]    shift_amt;
    reg [SIG_WIDTH-1:0]  a_sig;
    reg [SIG_WIDTH-1:0]  b_sig;
    reg [SIG_WIDTH-1:0]  pre_small;
    reg                  sticky;

    assign any_denorm = a_denorm | b_denorm;

    always @* begin
        a_eff_exp = (a_exp == {EXP_WIDTH{1'b0}}) ? {{EXP_WIDTH{1'b0}}, 1'b1}
                                                   : {1'b0, a_exp};
        b_eff_exp = (b_exp == {EXP_WIDTH{1'b0}}) ? {{EXP_WIDTH{1'b0}}, 1'b1}
                                                   : {1'b0, b_exp};

        a_sig = {(a_exp != {EXP_WIDTH{1'b0}}), a_mant, 3'b000};
        b_sig = {(b_exp != {EXP_WIDTH{1'b0}}), b_mant, 3'b000};

        if ((a_eff_exp > b_eff_exp) ||
            ((a_eff_exp == b_eff_exp) && (a_sig >= b_sig))) begin
            big_sign   = a_sign;
            small_sign = b_sign;
            common_exp = a_eff_exp;
            big_sig    = a_sig;
            pre_small  = b_sig;
            shift_amt  = a_eff_exp - b_eff_exp;
        end else begin
            big_sign   = b_sign;
            small_sign = a_sign;
            common_exp = b_eff_exp;
            big_sig    = b_sig;
            pre_small  = a_sig;
            shift_amt  = b_eff_exp - a_eff_exp;
        end

        if (shift_amt == {EXP_WIDTH+1{1'b0}}) begin
            small_sig = pre_small;
        end else if (shift_amt >= SIG_WIDTH[EXP_WIDTH:0]) begin
            small_sig = {{(SIG_WIDTH-1){1'b0}}, |pre_small};
        end else begin
            small_sig = pre_small >> shift_amt;
            sticky    = |(pre_small & (({SIG_WIDTH{1'b1}}) >> (SIG_WIDTH - shift_amt)));
            small_sig[0] = small_sig[0] | sticky;
        end
    end

endmodule