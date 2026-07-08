`timescale 1ns/1ps

module fpa_normalize_round #(
    parameter integer WIDTH = 32,
    parameter integer EXP_WIDTH = 8,
    parameter integer MANT_WIDTH = 23
)(
    input raw_sign,
    input [EXP_WIDTH:0] raw_exp,
    input [MANT_WIDTH+4:0] raw_sig,
    input raw_zero,
    input any_subnormal,
    input [2:0] rnd_mode,
    output reg [WIDTH-1:0] result,
    output reg [2:0] flags
);
    localparam integer SIG_WIDTH = MANT_WIDTH + 4;
    localparam integer RAW_WIDTH = MANT_WIDTH + 5;
    localparam [EXP_WIDTH:0] EXP_INF = {1'b0, {EXP_WIDTH{1'b1}}};

    reg [EXP_WIDTH:0] exp_norm;
    reg [SIG_WIDTH-1:0] sig_norm;
    reg [MANT_WIDTH:0] mant_main;
    reg guard_bit;
    reg round_bit;
    reg sticky_bit;
    reg increment;
    reg [MANT_WIDTH+1:0] rounded;
    reg [EXP_WIDTH-1:0] out_exp;
    reg [MANT_WIDTH-1:0] out_frac;
    reg inexact;
    integer k;

    always @* begin
        flags = 3'b000;
        result = {WIDTH{1'b0}};

        exp_norm = raw_exp;
        sig_norm = raw_sig[SIG_WIDTH-1:0];

        mant_main = {MANT_WIDTH+1{1'b0}};
        guard_bit = 1'b0;
        round_bit = 1'b0;
        sticky_bit = 1'b0;
        increment = 1'b0;
        rounded = {MANT_WIDTH+2{1'b0}};
        out_exp = {EXP_WIDTH{1'b0}};
        out_frac = {MANT_WIDTH{1'b0}};
        inexact = 1'b0;

        if (raw_zero) begin
            result = {raw_sign, {(WIDTH-1){1'b0}}};
            flags = 3'b000;
        end else begin
            if (raw_sig[RAW_WIDTH-1]) begin
                sig_norm = raw_sig[RAW_WIDTH-1:1];
                sig_norm[0] = raw_sig[1] | raw_sig[0];
                exp_norm = raw_exp + 1'b1;
            end else begin
                sig_norm = raw_sig[SIG_WIDTH-1:0];

                for (k = 0; k < SIG_WIDTH; k = k + 1) begin
                    if ((sig_norm[SIG_WIDTH-1] == 1'b0) && (exp_norm > 1)) begin
                        sig_norm = sig_norm << 1;
                        exp_norm = exp_norm - 1'b1;
                    end
                end
            end

            mant_main = sig_norm[SIG_WIDTH-1:3];
            guard_bit = sig_norm[2];
            round_bit = sig_norm[1];
            sticky_bit = sig_norm[0];
            inexact = guard_bit | round_bit | sticky_bit;

            case (rnd_mode)
                3'd0: increment = guard_bit & (round_bit | sticky_bit | mant_main[0]);
                3'd1: increment = 1'b0;
                3'd2: increment = (~raw_sign) & inexact;
                3'd3: increment = raw_sign & inexact;
                default: increment = guard_bit & (round_bit | sticky_bit | mant_main[0]);
            endcase

            rounded = {1'b0, mant_main} + {{(MANT_WIDTH+1){1'b0}}, increment};

            if (rounded[MANT_WIDTH+1]) begin
                mant_main = rounded[MANT_WIDTH+1:1];
                exp_norm = exp_norm + 1'b1;
            end else begin
                mant_main = rounded[MANT_WIDTH:0];
            end

            if (exp_norm >= EXP_INF) begin
                out_exp = {EXP_WIDTH{1'b1}};
                out_frac = {MANT_WIDTH{1'b0}};
                flags = 3'b010;
            end else if ((exp_norm == 0) || ((exp_norm == 1) && (mant_main[MANT_WIDTH] == 1'b0))) begin
                out_exp = {EXP_WIDTH{1'b0}};
                out_frac = mant_main[MANT_WIDTH-1:0];
                flags = 3'b001;
            end else begin
                out_exp = exp_norm[EXP_WIDTH-1:0];
                out_frac = mant_main[MANT_WIDTH-1:0];
                flags = any_subnormal ? 3'b001 : 3'b000;
            end

            result = {raw_sign, out_exp, out_frac};
        end
    end
endmodule