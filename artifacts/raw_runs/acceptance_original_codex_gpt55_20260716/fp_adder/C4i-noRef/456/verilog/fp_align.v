`timescale 1ns/1ps

module fp_align #(
    parameter integer WIDTH = 32,
    parameter integer EXP_WIDTH = 8,
    parameter integer MANT_WIDTH = WIDTH - EXP_WIDTH - 1
)(
    input sign_a,
    input sign_b,
    input [EXP_WIDTH-1:0] exp_a,
    input [EXP_WIDTH-1:0] exp_b,
    input [MANT_WIDTH-1:0] frac_a,
    input [MANT_WIDTH-1:0] frac_b,
    input a_denorm,
    input b_denorm,
    output reg sign_big,
    output reg sign_small,
    output reg subtract,
    output reg [EXP_WIDTH:0] exp_big,
    output reg [MANT_WIDTH+3:0] sig_big,
    output reg [MANT_WIDTH+3:0] sig_small
);

    localparam integer SIG_WIDTH = MANT_WIDTH + 4;

    reg [EXP_WIDTH:0] eff_exp_a;
    reg [EXP_WIDTH:0] eff_exp_b;
    reg [EXP_WIDTH:0] exp_diff;
    reg [SIG_WIDTH-1:0] sig_a;
    reg [SIG_WIDTH-1:0] sig_b;

    function [SIG_WIDTH-1:0] shift_right_sticky;
        input [SIG_WIDTH-1:0] value;
        input [EXP_WIDTH:0] shamt;

        integer i;
        reg sticky;
        reg [SIG_WIDTH-1:0] shifted;

        begin
            if (shamt >= SIG_WIDTH) begin
                shift_right_sticky = {{(SIG_WIDTH-1){1'b0}}, |value};
            end else begin
                shifted = value >> shamt;
                sticky = 1'b0;

                for (i = 0; i < SIG_WIDTH; i = i + 1) begin
                    if (i < shamt)
                        sticky = sticky | value[i];
                end

                shifted[0] = shifted[0] | sticky;
                shift_right_sticky = shifted;
            end
        end
    endfunction

    always @* begin
        eff_exp_a = a_denorm ? {{EXP_WIDTH{1'b0}}, 1'b1} : {1'b0, exp_a};
        eff_exp_b = b_denorm ? {{EXP_WIDTH{1'b0}}, 1'b1} : {1'b0, exp_b};

        sig_a = {~a_denorm, frac_a, 3'b000};
        sig_b = {~b_denorm, frac_b, 3'b000};

        subtract = sign_a ^ sign_b;

        if ((eff_exp_a > eff_exp_b) ||
            ((eff_exp_a == eff_exp_b) && (sig_a >= sig_b))) begin
            exp_big = eff_exp_a;
            sign_big = sign_a;
            sign_small = sign_b;
            sig_big = sig_a;

            exp_diff = eff_exp_a - eff_exp_b;
            sig_small = shift_right_sticky(sig_b, exp_diff);
        end else begin
            exp_big = eff_exp_b;
            sign_big = sign_b;
            sign_small = sign_a;
            sig_big = sig_b;

            exp_diff = eff_exp_b - eff_exp_a;
            sig_small = shift_right_sticky(sig_a, exp_diff);
        end
    end

endmodule