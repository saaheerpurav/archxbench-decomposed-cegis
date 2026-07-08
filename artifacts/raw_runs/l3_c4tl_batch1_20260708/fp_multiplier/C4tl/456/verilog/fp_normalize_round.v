`timescale 1ns/1ps

module fp_normalize_round #(
    parameter EXP_WIDTH  = 8,
    parameter MANT_WIDTH = 23,
    parameter WIDTH      = 1 + EXP_WIDTH + MANT_WIDTH
)(
    input result_sign,
    input signed [EXP_WIDTH+1:0] base_exp,
    input [((MANT_WIDTH+1)*2)-1:0] sig_product,
    input [2:0] rnd_mode,
    output reg [WIDTH-1:0] product,
    output reg [2:0] exception_flags
);

    localparam integer PROD_WIDTH = (MANT_WIDTH + 1) * 2;
    localparam integer MAX_EXP    = (1 << EXP_WIDTH) - 1;

    reg signed [EXP_WIDTH+2:0] norm_exp;
    reg signed [EXP_WIDTH+2:0] final_exp;

    reg [MANT_WIDTH-1:0] mant_pre_round;
    reg guard_bit;
    reg round_bit;
    reg sticky_bit;
    reg round_increment;
    reg [MANT_WIDTH:0] rounded_mant;

    integer i;

    always @(*) begin
        product = {WIDTH{1'b0}};
        exception_flags = 3'b000;

        norm_exp = {EXP_WIDTH+3{1'b0}};
        final_exp = {EXP_WIDTH+3{1'b0}};
        mant_pre_round = {MANT_WIDTH{1'b0}};
        guard_bit = 1'b0;
        round_bit = 1'b0;
        sticky_bit = 1'b0;
        round_increment = 1'b0;
        rounded_mant = {MANT_WIDTH+1{1'b0}};

        if (sig_product == {PROD_WIDTH{1'b0}}) begin
            product = {result_sign, {EXP_WIDTH{1'b0}}, {MANT_WIDTH{1'b0}}};
            exception_flags = 3'b001;
        end else begin
            if (sig_product[PROD_WIDTH-1]) begin
                norm_exp = base_exp + 1'b1;
                mant_pre_round = sig_product[PROD_WIDTH-2:MANT_WIDTH+1];
                guard_bit = sig_product[MANT_WIDTH];

                if (MANT_WIDTH >= 1)
                    round_bit = sig_product[MANT_WIDTH-1];

                sticky_bit = 1'b0;
                for (i = 0; i <= MANT_WIDTH-2; i = i + 1)
                    sticky_bit = sticky_bit | sig_product[i];
            end else begin
                norm_exp = base_exp;
                mant_pre_round = sig_product[PROD_WIDTH-3:MANT_WIDTH];
                guard_bit = sig_product[MANT_WIDTH-1];

                if (MANT_WIDTH >= 2)
                    round_bit = sig_product[MANT_WIDTH-2];

                sticky_bit = 1'b0;
                for (i = 0; i <= MANT_WIDTH-3; i = i + 1)
                    sticky_bit = sticky_bit | sig_product[i];
            end

            case (rnd_mode)
                3'b000: round_increment = guard_bit &&
                                          (round_bit || sticky_bit || mant_pre_round[0]);
                3'b001: round_increment = 1'b0;
                3'b010: round_increment = result_sign &&
                                          (guard_bit || round_bit || sticky_bit);
                3'b011: round_increment = !result_sign &&
                                          (guard_bit || round_bit || sticky_bit);
                default: round_increment = guard_bit &&
                                           (round_bit || sticky_bit || mant_pre_round[0]);
            endcase

            rounded_mant = {1'b0, mant_pre_round} + round_increment;
            final_exp = norm_exp;

            if (rounded_mant[MANT_WIDTH]) begin
                final_exp = norm_exp + 1'b1;
                rounded_mant = {1'b0, {MANT_WIDTH{1'b0}}};
            end

            if (final_exp >= MAX_EXP) begin
                product = {result_sign, {EXP_WIDTH{1'b1}}, {MANT_WIDTH{1'b0}}};
                exception_flags = 3'b010;
            end else if (final_exp <= 0) begin
                product = {result_sign, {EXP_WIDTH{1'b0}}, {MANT_WIDTH{1'b0}}};
                exception_flags = 3'b001;
            end else begin
                product = {
                    result_sign,
                    final_exp[EXP_WIDTH-1:0],
                    rounded_mant[MANT_WIDTH-1:0]
                };
                exception_flags = 3'b000;
            end
        end
    end

endmodule