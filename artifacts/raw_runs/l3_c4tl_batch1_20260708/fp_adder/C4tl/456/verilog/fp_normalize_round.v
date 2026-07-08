`timescale 1ns/1ps

module fp_normalize_round #(
    parameter integer WIDTH = 32,
    parameter integer EXP_WIDTH = 8,
    parameter integer MANT_WIDTH = 23
)(
    input raw_sign,
    input [EXP_WIDTH-1:0] raw_exp,
    input [MANT_WIDTH+4:0] raw_sum,
    input raw_zero,
    input [2:0] rnd_mode,
    input underflow_hint,
    output reg [WIDTH-1:0] result,
    output reg [2:0] flags
);

    localparam integer SUM_WIDTH = MANT_WIDTH + 5;
    localparam [EXP_WIDTH-1:0] EXP_ALL_ONES = {EXP_WIDTH{1'b1}};

    reg [SUM_WIDTH-1:0] norm;
    reg [EXP_WIDTH:0] exp_work;
    reg sign_work;

    reg guard_bit;
    reg round_bit;
    reg sticky_bit;
    reg lsb_bit;
    reg any_round_bits;
    reg increment;

    reg [MANT_WIDTH:0] main_sig;
    reg [MANT_WIDTH+1:0] rounded_sig;

    integer j;

    always @* begin
        result = {WIDTH{1'b0}};
        flags = 3'b000;

        sign_work = raw_sign;
        exp_work = {1'b0, raw_exp};
        norm = raw_sum;

        if (raw_zero || raw_sum == {SUM_WIDTH{1'b0}}) begin
            result = {(rnd_mode == 3'd3), {EXP_WIDTH{1'b0}}, {MANT_WIDTH{1'b0}}};
            flags = 3'b000;
        end else begin
            if (norm[MANT_WIDTH+4]) begin
                norm = norm >> 1;
                norm[0] = raw_sum[1] | raw_sum[0];
                exp_work = exp_work + 1'b1;
            end else begin
                for (j = 0; j < MANT_WIDTH + 4; j = j + 1) begin
                    if (!norm[MANT_WIDTH+3] && (exp_work > 1)) begin
                        norm = norm << 1;
                        exp_work = exp_work - 1'b1;
                    end
                end
            end

            main_sig = norm[MANT_WIDTH+3:3];
            guard_bit = norm[2];
            round_bit = norm[1];
            sticky_bit = norm[0];
            lsb_bit = main_sig[0];
            any_round_bits = guard_bit | round_bit | sticky_bit;

            increment = 1'b0;
            case (rnd_mode)
                3'd0: increment = guard_bit & (round_bit | sticky_bit | lsb_bit);
                3'd1: increment = 1'b0;
                3'd2: increment = !sign_work & any_round_bits;
                3'd3: increment =  sign_work & any_round_bits;
                default: increment = guard_bit & (round_bit | sticky_bit | lsb_bit);
            endcase

            rounded_sig = {1'b0, main_sig} + increment;

            if (rounded_sig[MANT_WIDTH+1]) begin
                rounded_sig = rounded_sig >> 1;
                exp_work = exp_work + 1'b1;
            end

            if (exp_work >= {1'b0, EXP_ALL_ONES}) begin
                result = {sign_work, EXP_ALL_ONES, {MANT_WIDTH{1'b0}}};
                flags = 3'b010;
            end else if (exp_work == 0) begin
                result = {sign_work, {EXP_WIDTH{1'b0}}, rounded_sig[MANT_WIDTH-1:0]};
                flags = {2'b00, underflow_hint};
            end else begin
                result = {sign_work, exp_work[EXP_WIDTH-1:0], rounded_sig[MANT_WIDTH-1:0]};
                flags = {2'b00, underflow_hint};
            end
        end
    end

endmodule