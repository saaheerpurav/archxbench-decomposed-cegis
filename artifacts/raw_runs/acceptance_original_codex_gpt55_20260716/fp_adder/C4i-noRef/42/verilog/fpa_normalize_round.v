`timescale 1ns/1ps

module fpa_normalize_round #(
    parameter integer WIDTH = 32,
    parameter integer EXP_WIDTH = 8,
    parameter integer MANT_WIDTH = 23
)(
    input sign_in,
    input [EXP_WIDTH:0] exp_in,
    input [MANT_WIDTH+4:0] mag_in,
    input zero_in,
    input underflow_hint,
    input [2:0] rnd_mode,
    output reg [WIDTH-1:0] sum_out,
    output reg [2:0] flags_out
);

    localparam integer SIG_WIDTH = MANT_WIDTH + 4;
    localparam integer RAW_WIDTH = MANT_WIDTH + 5;

    localparam [EXP_WIDTH:0] EXP_ONE = {{EXP_WIDTH{1'b0}}, 1'b1};
    localparam [EXP_WIDTH:0] EXP_INF = {1'b0, {EXP_WIDTH{1'b1}}};

    reg [EXP_WIDTH:0] exp_norm;
    reg [SIG_WIDTH-1:0] sig_norm;

    reg [MANT_WIDTH:0] mant_main;
    reg guard_bit;
    reg round_bit;
    reg sticky_bit;
    reg inexact;
    reg increment;

    reg [MANT_WIDTH+1:0] rounded;
    reg [EXP_WIDTH-1:0] out_exp;
    reg [MANT_WIDTH-1:0] out_frac;
    reg zero_sign;

    integer i;

    always @* begin
        sum_out = {WIDTH{1'b0}};
        flags_out = 3'b000;

        exp_norm = exp_in;
        sig_norm = mag_in[SIG_WIDTH-1:0];

        mant_main = {MANT_WIDTH+1{1'b0}};
        guard_bit = 1'b0;
        round_bit = 1'b0;
        sticky_bit = 1'b0;
        inexact = 1'b0;
        increment = 1'b0;
        rounded = {MANT_WIDTH+2{1'b0}};
        out_exp = {EXP_WIDTH{1'b0}};
        out_frac = {MANT_WIDTH{1'b0}};
        zero_sign = 1'b0;

        if (zero_in || (mag_in == {RAW_WIDTH{1'b0}})) begin
            zero_sign = (rnd_mode == 3'd3);
            sum_out = {zero_sign, {(WIDTH-1){1'b0}}};
            flags_out = 3'b000;
        end else begin
            if (mag_in[RAW_WIDTH-1]) begin
                sig_norm = mag_in[RAW_WIDTH-1:1];
                sig_norm[0] = mag_in[1] | mag_in[0];
                exp_norm = exp_in + EXP_ONE;
            end else begin
                sig_norm = mag_in[SIG_WIDTH-1:0];

                for (i = 0; i < SIG_WIDTH; i = i + 1) begin
                    if (!sig_norm[SIG_WIDTH-1] && (exp_norm > EXP_ONE)) begin
                        sig_norm = sig_norm << 1;
                        exp_norm = exp_norm - EXP_ONE;
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
                3'd2: increment = (~sign_in) & inexact;
                3'd3: increment = sign_in & inexact;
                default: increment = guard_bit & (round_bit | sticky_bit | mant_main[0]);
            endcase

            rounded = {1'b0, mant_main} + {{(MANT_WIDTH+1){1'b0}}, increment};

            if (rounded[MANT_WIDTH+1]) begin
                mant_main = rounded[MANT_WIDTH+1:1];
                exp_norm = exp_norm + EXP_ONE;
            end else begin
                mant_main = rounded[MANT_WIDTH:0];
            end

            if (exp_norm >= EXP_INF) begin
                out_exp = {EXP_WIDTH{1'b1}};
                out_frac = {MANT_WIDTH{1'b0}};
                flags_out = 3'b010;
            end else if ((exp_norm == {EXP_WIDTH+1{1'b0}}) ||
                         ((exp_norm == EXP_ONE) && !mant_main[MANT_WIDTH])) begin
                out_exp = {EXP_WIDTH{1'b0}};
                out_frac = mant_main[MANT_WIDTH-1:0];
                flags_out = 3'b001;
            end else begin
                out_exp = exp_norm[EXP_WIDTH-1:0];
                out_frac = mant_main[MANT_WIDTH-1:0];
                flags_out = underflow_hint ? 3'b001 : 3'b000;
            end

            sum_out = {sign_in, out_exp, out_frac};
        end
    end

endmodule