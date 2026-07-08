`timescale 1ns/1ps

module fp_normalize_round #(
    parameter EXP_WIDTH  = 8,
    parameter MANT_WIDTH = 23,
    parameter WIDTH      = 1 + EXP_WIDTH + MANT_WIDTH
)(
    input  wire                          result_sign,
    input  wire signed [EXP_WIDTH+2:0]   raw_exp,
    input  wire [((MANT_WIDTH+1)*2)-1:0] sig_product,
    input  wire                          mult_zero,
    input  wire [2:0]                    rnd_mode,
    output reg  [WIDTH-1:0]              result,
    output reg  [2:0]                    flags
);

    localparam SIG_WIDTH  = MANT_WIDTH + 1;
    localparam PROD_WIDTH = SIG_WIDTH * 2;

    localparam [EXP_WIDTH-1:0]  EXP_ZERO     = {EXP_WIDTH{1'b0}};
    localparam [EXP_WIDTH-1:0]  EXP_ALL_ONES = {EXP_WIDTH{1'b1}};
    localparam [MANT_WIDTH-1:0] MANT_ZERO    = {MANT_WIDTH{1'b0}};

    localparam signed [EXP_WIDTH+2:0] MAX_FINITE_EXP =
        {1'b0, EXP_ALL_ONES};

    integer i;

    reg signed [EXP_WIDTH+2:0] norm_exp;
    reg signed [EXP_WIDTH+2:0] final_exp;

    reg [MANT_WIDTH-1:0] mant_pre;
    reg                  guard_bit;
    reg                  round_bit;
    reg                  sticky_bit;
    reg                  increment;

    reg [MANT_WIDTH:0] rounded_mant;

    always @* begin
        result       = {WIDTH{1'b0}};
        flags        = 3'b000;

        norm_exp     = raw_exp;
        final_exp    = raw_exp;
        mant_pre     = MANT_ZERO;
        guard_bit    = 1'b0;
        round_bit    = 1'b0;
        sticky_bit   = 1'b0;
        increment    = 1'b0;
        rounded_mant = {(MANT_WIDTH+1){1'b0}};

        if (mult_zero || (sig_product == {PROD_WIDTH{1'b0}})) begin
            result = {result_sign, EXP_ZERO, MANT_ZERO};
            flags  = 3'b001;
        end else begin
            if (sig_product[PROD_WIDTH-1]) begin
                norm_exp  = raw_exp + 1'b1;
                mant_pre  = sig_product[PROD_WIDTH-2 -: MANT_WIDTH];
                guard_bit = sig_product[MANT_WIDTH];
                round_bit = sig_product[MANT_WIDTH-1];

                sticky_bit = 1'b0;
                for (i = 0; i <= MANT_WIDTH-2; i = i + 1)
                    sticky_bit = sticky_bit | sig_product[i];
            end else begin
                norm_exp  = raw_exp;
                mant_pre  = sig_product[PROD_WIDTH-3 -: MANT_WIDTH];
                guard_bit = sig_product[MANT_WIDTH-1];
                round_bit = sig_product[MANT_WIDTH-2];

                sticky_bit = 1'b0;
                for (i = 0; i <= MANT_WIDTH-3; i = i + 1)
                    sticky_bit = sticky_bit | sig_product[i];
            end

            case (rnd_mode)
                3'b000: increment = guard_bit &&
                                    (round_bit || sticky_bit || mant_pre[0]);
                3'b001: increment = 1'b0;
                3'b010: increment = result_sign &&
                                    (guard_bit || round_bit || sticky_bit);
                3'b011: increment = !result_sign &&
                                    (guard_bit || round_bit || sticky_bit);
                default: increment = guard_bit &&
                                     (round_bit || sticky_bit || mant_pre[0]);
            endcase

            rounded_mant = {1'b0, mant_pre} + {{MANT_WIDTH{1'b0}}, increment};
            final_exp    = norm_exp;

            if (rounded_mant[MANT_WIDTH]) begin
                final_exp = norm_exp + 1'b1;
                mant_pre  = MANT_ZERO;
            end else begin
                mant_pre = rounded_mant[MANT_WIDTH-1:0];
            end

            if (final_exp >= MAX_FINITE_EXP) begin
                result = {result_sign, EXP_ALL_ONES, MANT_ZERO};
                flags  = 3'b010;
            end else if (final_exp <= 0) begin
                result = {result_sign, EXP_ZERO, MANT_ZERO};
                flags  = 3'b001;
            end else begin
                result = {result_sign, final_exp[EXP_WIDTH-1:0], mant_pre};
                flags  = 3'b000;
            end
        end
    end

endmodule