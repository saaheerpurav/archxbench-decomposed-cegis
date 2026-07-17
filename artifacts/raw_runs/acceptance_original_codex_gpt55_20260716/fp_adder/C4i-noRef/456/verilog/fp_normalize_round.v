`timescale 1ns/1ps

module fp_normalize_round #(
    parameter integer WIDTH = 32,
    parameter integer EXP_WIDTH = 8,
    parameter integer MANT_WIDTH = WIDTH - EXP_WIDTH - 1
)(
    input sign_in,
    input [EXP_WIDTH:0] exp_in,
    input [MANT_WIDTH+4:0] sig_in,
    input is_zero,
    input [2:0] rnd_mode,
    input denorm_input,
    output reg [WIDTH-1:0] result,
    output reg [2:0] flags
);

    localparam integer SIG_WIDTH = MANT_WIDTH + 5;
    localparam [EXP_WIDTH:0] MAX_EXP = {1'b0, {EXP_WIDTH{1'b1}}};

    reg [EXP_WIDTH:0] exp_work;
    reg [SIG_WIDTH-1:0] sig_work;
    reg [MANT_WIDTH:0] main_sig;
    reg guard_bit;
    reg round_bit;
    reg sticky_bit;
    reg inexact;
    reg increment;
    reg [MANT_WIDTH+1:0] rounded_sig;
    reg overflow;
    reg underflow;
    reg subnormal;
    reg [MANT_WIDTH-1:0] max_frac;
    integer i;

    always @* begin
        exp_work = exp_in;
        sig_work = sig_in;
        result = {WIDTH{1'b0}};
        flags = 3'b000;

        main_sig = {(MANT_WIDTH+1){1'b0}};
        guard_bit = 1'b0;
        round_bit = 1'b0;
        sticky_bit = 1'b0;
        inexact = 1'b0;
        increment = 1'b0;
        rounded_sig = {(MANT_WIDTH+2){1'b0}};
        overflow = 1'b0;
        underflow = 1'b0;
        subnormal = 1'b0;
        max_frac = {MANT_WIDTH{1'b1}};

        if (is_zero) begin
            result = {(rnd_mode == 3'b011), {EXP_WIDTH{1'b0}}, {MANT_WIDTH{1'b0}}};
            flags = 3'b000;
        end else begin
            if (sig_work[MANT_WIDTH+4]) begin
                sticky_bit = sig_work[1] | sig_work[0];
                sig_work = sig_work >> 1;
                sig_work[0] = sticky_bit;
                exp_work = exp_work + 1'b1;
            end else begin
                for (i = 0; i < MANT_WIDTH + 4; i = i + 1) begin
                    if (!sig_work[MANT_WIDTH+3] && (exp_work > 1)) begin
                        sig_work = sig_work << 1;
                        exp_work = exp_work - 1'b1;
                    end
                end
            end

            subnormal = (exp_work == 1) && !sig_work[MANT_WIDTH+3];

            main_sig = sig_work[MANT_WIDTH+3:3];
            guard_bit = sig_work[2];
            round_bit = sig_work[1];
            sticky_bit = sig_work[0];
            inexact = guard_bit | round_bit | sticky_bit;

            case (rnd_mode)
                3'b000: increment = guard_bit & (round_bit | sticky_bit | main_sig[0]);
                3'b001: increment = 1'b0;
                3'b010: increment = !sign_in & inexact;
                3'b011: increment = sign_in & inexact;
                default: increment = guard_bit & (round_bit | sticky_bit | main_sig[0]);
            endcase

            rounded_sig = {1'b0, main_sig} + increment;

            if (rounded_sig[MANT_WIDTH+1]) begin
                rounded_sig = rounded_sig >> 1;
                exp_work = exp_work + 1'b1;
                subnormal = 1'b0;
            end

            if (exp_work >= MAX_EXP) begin
                overflow = 1'b1;

                case (rnd_mode)
                    3'b001: result = {sign_in, {EXP_WIDTH{1'b1}}, max_frac};
                    3'b010: result = sign_in
                        ? {sign_in, {EXP_WIDTH{1'b1}}, max_frac}
                        : {sign_in, {EXP_WIDTH{1'b1}}, {MANT_WIDTH{1'b0}}};
                    3'b011: result = sign_in
                        ? {sign_in, {EXP_WIDTH{1'b1}}, {MANT_WIDTH{1'b0}}}
                        : {sign_in, {EXP_WIDTH{1'b1}}, max_frac};
                    default: result = {sign_in, {EXP_WIDTH{1'b1}}, {MANT_WIDTH{1'b0}}};
                endcase
            end else if (subnormal || (exp_work == 0)) begin
                underflow = inexact | (rounded_sig[MANT_WIDTH-1:0] != {MANT_WIDTH{1'b0}});
                result = {sign_in, {EXP_WIDTH{1'b0}}, rounded_sig[MANT_WIDTH-1:0]};
            end else begin
                result = {sign_in, exp_work[EXP_WIDTH-1:0], rounded_sig[MANT_WIDTH-1:0]};
            end

            flags[2] = 1'b0;
            flags[1] = overflow;
            flags[0] = denorm_input | underflow;
        end
    end

endmodule