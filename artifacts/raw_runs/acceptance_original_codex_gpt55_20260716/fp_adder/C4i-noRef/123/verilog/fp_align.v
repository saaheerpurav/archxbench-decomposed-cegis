`timescale 1ns/1ps

module fp_align #(
    parameter integer EXP_WIDTH  = 8,
    parameter integer MANT_WIDTH = 23
)(
    input  wire                  sign_a,
    input  wire                  sign_b,
    input  wire [EXP_WIDTH-1:0]  exp_a,
    input  wire [EXP_WIDTH-1:0]  exp_b,
    input  wire [MANT_WIDTH-1:0] mant_a,
    input  wire [MANT_WIDTH-1:0] mant_b,

    output reg                   sign_large,
    output reg                   sign_small,
    output reg                   large_is_a,
    output reg  [EXP_WIDTH-1:0]  align_exp,
    output reg  [MANT_WIDTH+3:0] large_sig,
    output reg  [MANT_WIDTH+3:0] small_sig
);

    localparam integer EXT_WIDTH = MANT_WIDTH + 4;

    reg [EXT_WIDTH-1:0] sig_a;
    reg [EXT_WIDTH-1:0] sig_b;
    reg [EXP_WIDTH-1:0] eff_exp_a;
    reg [EXP_WIDTH-1:0] eff_exp_b;

    reg [EXT_WIDTH-1:0] big_sig;
    reg [EXT_WIDTH-1:0] sml_sig;
    reg [EXP_WIDTH-1:0] big_exp;
    reg [EXP_WIDTH-1:0] sml_exp;
    reg                 big_sign;
    reg                 sml_sign;

    reg [EXP_WIDTH:0] shift_amt;

    function [EXT_WIDTH-1:0] shift_right_sticky;
        input [EXT_WIDTH-1:0] value;
        input [EXP_WIDTH:0]   shamt;

        integer i;
        reg sticky;
        reg [EXT_WIDTH-1:0] shifted;
        begin
            if (shamt >= EXT_WIDTH) begin
                shift_right_sticky = {{(EXT_WIDTH-1){1'b0}}, |value};
            end else begin
                shifted = value >> shamt;
                sticky = 1'b0;

                for (i = 0; i < EXT_WIDTH; i = i + 1) begin
                    if (i < shamt)
                        sticky = sticky | value[i];
                end

                shifted[0] = shifted[0] | sticky;
                shift_right_sticky = shifted;
            end
        end
    endfunction

    always @* begin
        sig_a = {(exp_a != {EXP_WIDTH{1'b0}}), mant_a, 3'b000};
        sig_b = {(exp_b != {EXP_WIDTH{1'b0}}), mant_b, 3'b000};

        eff_exp_a = (exp_a == {EXP_WIDTH{1'b0}})
                  ? {{(EXP_WIDTH-1){1'b0}}, 1'b1}
                  : exp_a;
        eff_exp_b = (exp_b == {EXP_WIDTH{1'b0}})
                  ? {{(EXP_WIDTH-1){1'b0}}, 1'b1}
                  : exp_b;

        if ((eff_exp_a > eff_exp_b) ||
            ((eff_exp_a == eff_exp_b) && (sig_a >= sig_b))) begin
            big_sig    = sig_a;
            sml_sig    = sig_b;
            big_exp    = eff_exp_a;
            sml_exp    = eff_exp_b;
            big_sign   = sign_a;
            sml_sign   = sign_b;
            large_is_a = 1'b1;
        end else begin
            big_sig    = sig_b;
            sml_sig    = sig_a;
            big_exp    = eff_exp_b;
            sml_exp    = eff_exp_a;
            big_sign   = sign_b;
            sml_sign   = sign_a;
            large_is_a = 1'b0;
        end

        shift_amt = {1'b0, big_exp} - {1'b0, sml_exp};

        sign_large = big_sign;
        sign_small = sml_sign;
        align_exp  = big_exp;
        large_sig  = big_sig;
        small_sig  = shift_right_sticky(sml_sig, shift_amt);
    end

endmodule