`timescale 1ns/1ps

module fp_normalize_round #(
    parameter EXP_WIDTH  = 8,
    parameter MANT_WIDTH = 23,
    parameter WIDTH      = 1 + EXP_WIDTH + MANT_WIDTH
)(
    input result_sign,
    input signed [EXP_WIDTH+1:0] exp_sum,
    input [(2*(MANT_WIDTH+1))-1:0] sig_product,
    input [2:0] rnd_mode,
    output reg [WIDTH-1:0] product,
    output reg [2:0] exception_flags
);

    localparam integer PROD_WIDTH = 2 * (MANT_WIDTH + 1);
    localparam integer EXP_MAX    = (1 << EXP_WIDTH) - 1;
    localparam integer TARGET_MSB = 2 * MANT_WIDTH;

    integer i;
    integer lead_index;
    integer left_shift;

    reg signed [EXP_WIDTH+2:0] norm_exp;
    reg [PROD_WIDTH-1:0] norm_product;

    reg [MANT_WIDTH:0] mant_keep;
    reg guard_bit;
    reg round_bit;
    reg sticky_bit;
    reg inexact;
    reg round_inc;

    reg [MANT_WIDTH+1:0] rounded_mant;
    reg [EXP_WIDTH-1:0] final_exp;
    reg [MANT_WIDTH-1:0] final_mant;

    always @(*) begin
        product = {WIDTH{1'b0}};
        exception_flags = 3'b000;

        norm_exp = exp_sum;
        norm_product = {PROD_WIDTH{1'b0}};
        mant_keep = {(MANT_WIDTH+1){1'b0}};
        guard_bit = 1'b0;
        round_bit = 1'b0;
        sticky_bit = 1'b0;
        inexact = 1'b0;
        round_inc = 1'b0;
        rounded_mant = {(MANT_WIDTH+2){1'b0}};
        final_exp = {EXP_WIDTH{1'b0}};
        final_mant = {MANT_WIDTH{1'b0}};

        if (sig_product == {PROD_WIDTH{1'b0}}) begin
            product = {result_sign, {EXP_WIDTH{1'b0}}, {MANT_WIDTH{1'b0}}};
            exception_flags = 3'b001;
        end else begin
            if (sig_product[PROD_WIDTH-1]) begin
                norm_exp = exp_sum + 1;
                norm_product = sig_product >> 1;
            end else begin
                lead_index = 0;
                for (i = PROD_WIDTH-2; i >= 0; i = i - 1) begin
                    if (sig_product[i] && (lead_index == 0)) begin
                        lead_index = i;
                    end
                end

                left_shift = TARGET_MSB - lead_index;
                if (left_shift > 0) begin
                    norm_product = sig_product << left_shift;
                    norm_exp = exp_sum - left_shift;
                end else begin
                    norm_product = sig_product;
                    norm_exp = exp_sum;
                end
            end

            mant_keep = norm_product[TARGET_MSB -: (MANT_WIDTH+1)];

            if (MANT_WIDTH > 0) begin
                guard_bit = norm_product[MANT_WIDTH-1];
            end else begin
                guard_bit = 1'b0;
            end

            if (MANT_WIDTH > 1) begin
                round_bit = norm_product[MANT_WIDTH-2];
                sticky_bit = |norm_product[MANT_WIDTH-3:0];
            end else begin
                round_bit = 1'b0;
                sticky_bit = 1'b0;
            end

            inexact = guard_bit | round_bit | sticky_bit;

            case (rnd_mode)
                3'b000: round_inc = guard_bit & (round_bit | sticky_bit | mant_keep[0]);
                3'b001: round_inc = 1'b0;
                3'b010: round_inc = result_sign & inexact;
                3'b011: round_inc = ~result_sign & inexact;
                default: round_inc = guard_bit & (round_bit | sticky_bit | mant_keep[0]);
            endcase

            rounded_mant = {1'b0, mant_keep} + round_inc;

            if (rounded_mant[MANT_WIDTH+1]) begin
                norm_exp = norm_exp + 1;
                mant_keep = rounded_mant[MANT_WIDTH+1:1];
            end else begin
                mant_keep = rounded_mant[MANT_WIDTH:0];
            end

            if (norm_exp >= EXP_MAX) begin
                product = {result_sign, {EXP_WIDTH{1'b1}}, {MANT_WIDTH{1'b0}}};
                exception_flags = 3'b010;
            end else if ((norm_exp <= 0) || !mant_keep[MANT_WIDTH]) begin
                product = {result_sign, {EXP_WIDTH{1'b0}}, {MANT_WIDTH{1'b0}}};
                exception_flags = 3'b001;
            end else begin
                final_exp = norm_exp[EXP_WIDTH-1:0];
                final_mant = mant_keep[MANT_WIDTH-1:0];
                product = {result_sign, final_exp, final_mant};
                exception_flags = 3'b000;
            end
        end
    end

endmodule