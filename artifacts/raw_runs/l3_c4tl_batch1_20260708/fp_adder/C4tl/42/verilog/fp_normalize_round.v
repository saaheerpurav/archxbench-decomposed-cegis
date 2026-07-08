`timescale 1ns/1ps

module fp_normalize_round #(
    parameter integer WIDTH = 32,
    parameter integer EXP_WIDTH = 8,
    parameter integer MANT_WIDTH = 23
)(
    input raw_sign,
    input [EXP_WIDTH:0] raw_exp,
    input [MANT_WIDTH+4:0] raw_sig,
    input raw_zero,
    input [2:0] rnd_mode,
    input any_denorm,
    output reg [WIDTH-1:0] result,
    output reg [2:0] flags
);
    localparam [EXP_WIDTH:0] MAX_EXP = {1'b0, {EXP_WIDTH{1'b1}}};

    reg sign;
    reg [EXP_WIDTH:0] exp;
    reg [MANT_WIDTH+4:0] sig;
    reg [MANT_WIDTH:0] mant_main;
    reg guard_bit;
    reg round_bit;
    reg sticky_bit;
    reg increment;
    reg [MANT_WIDTH+1:0] rounded;
    reg lost_sticky;
    integer j;

    always @* begin
        sign = raw_sign;
        exp = raw_exp;
        sig = raw_sig;
        flags = 3'b000;
        result = {WIDTH{1'b0}};

        if (raw_zero) begin
            result = {(rnd_mode == 3'd3), {EXP_WIDTH{1'b0}}, {MANT_WIDTH{1'b0}}};
            flags = 3'b000;
        end else begin
            if (sig[MANT_WIDTH+4]) begin
                lost_sticky = sig[0];
                sig = sig >> 1;
                sig[0] = sig[0] | lost_sticky;
                exp = exp + 1'b1;
            end else begin
                for (j = 0; j < MANT_WIDTH + 4; j = j + 1) begin
                    if (!sig[MANT_WIDTH+3] && (exp > 1)) begin
                        sig = sig << 1;
                        exp = exp - 1'b1;
                    end
                end
            end

            if (!sig[MANT_WIDTH+3] && (exp == 1)) begin
                exp = {EXP_WIDTH+1{1'b0}};
            end

            mant_main = sig[MANT_WIDTH+3:3];
            guard_bit = sig[2];
            round_bit = sig[1];
            sticky_bit = sig[0];

            increment = 1'b0;
            case (rnd_mode)
                3'd0: increment = guard_bit &&
                                 (round_bit || sticky_bit || mant_main[0]);
                3'd1: increment = 1'b0;
                3'd2: increment = !sign &&
                                 (guard_bit || round_bit || sticky_bit);
                3'd3: increment = sign &&
                                 (guard_bit || round_bit || sticky_bit);
                default: increment = guard_bit &&
                                    (round_bit || sticky_bit || mant_main[0]);
            endcase

            rounded = {1'b0, mant_main} + {{(MANT_WIDTH+1){1'b0}}, increment};

            if (rounded[MANT_WIDTH+1]) begin
                rounded = rounded >> 1;
                exp = exp + 1'b1;
            end

            if (exp >= MAX_EXP) begin
                result = {sign, {EXP_WIDTH{1'b1}}, {MANT_WIDTH{1'b0}}};
                flags = 3'b010;
            end else begin
                result = {sign, exp[EXP_WIDTH-1:0], rounded[MANT_WIDTH-1:0]};
                flags = any_denorm ? 3'b001 : 3'b000;
            end
        end
    end
endmodule