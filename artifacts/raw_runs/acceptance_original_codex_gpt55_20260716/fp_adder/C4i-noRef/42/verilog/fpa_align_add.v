`timescale 1ns/1ps

module fpa_align_add #(
    parameter integer WIDTH = 32,
    parameter integer EXP_WIDTH = 8,
    parameter integer MANT_WIDTH = 23
)(
    input  wire                    sign_a,
    input  wire                    sign_b,
    input  wire [EXP_WIDTH-1:0]    exp_a,
    input  wire [EXP_WIDTH-1:0]    exp_b,
    input  wire [MANT_WIDTH-1:0]   frac_a,
    input  wire [MANT_WIDTH-1:0]   frac_b,
    input  wire [2:0]              rnd_mode,

    output reg                     result_sign,
    output reg  [EXP_WIDTH:0]      result_exp,
    output reg  [MANT_WIDTH+4:0]   result_mag,
    output wire [MANT_WIDTH+4:0]   result_mant,
    output wire [MANT_WIDTH+4:0]   result_sig,
    output reg                     result_zero,

    output wire                    raw_sign,
    output wire [EXP_WIDTH:0]      raw_exp,
    output wire [MANT_WIDTH+4:0]   raw_sig,
    output wire                    raw_zero,

    output reg                     any_subnormal,
    output reg                     op_sub
);

    localparam integer SIG_WIDTH = MANT_WIDTH + 4;
    localparam integer RAW_WIDTH = MANT_WIDTH + 5;

    wire exp_a_zero;
    wire exp_b_zero;
    wire frac_a_zero;
    wire frac_b_zero;

    wire [EXP_WIDTH:0] eff_exp_a;
    wire [EXP_WIDTH:0] eff_exp_b;

    wire [SIG_WIDTH-1:0] sig_a_unaligned;
    wire [SIG_WIDTH-1:0] sig_b_unaligned;

    reg [EXP_WIDTH:0] exp_big;
    reg [EXP_WIDTH:0] exp_small;
    reg sign_big;
    reg sign_small;

    reg [SIG_WIDTH-1:0] sig_big;
    reg [SIG_WIDTH-1:0] sig_small_pre;
    reg [SIG_WIDTH-1:0] sig_small;

    reg [EXP_WIDTH:0] shift_amt;
    reg sticky;

    reg [RAW_WIDTH-1:0] sig_big_ext;
    reg [RAW_WIDTH-1:0] sig_small_ext;
    reg [RAW_WIDTH-1:0] add_result;
    reg [RAW_WIDTH-1:0] sub_result;

    integer i;

    assign result_mant = result_mag;
    assign result_sig  = result_mag;

    assign raw_sign = result_sign;
    assign raw_exp  = result_exp;
    assign raw_sig  = result_mag;
    assign raw_zero = result_zero;

    assign exp_a_zero  = (exp_a == {EXP_WIDTH{1'b0}});
    assign exp_b_zero  = (exp_b == {EXP_WIDTH{1'b0}});
    assign frac_a_zero = (frac_a == {MANT_WIDTH{1'b0}});
    assign frac_b_zero = (frac_b == {MANT_WIDTH{1'b0}});

    assign eff_exp_a = exp_a_zero ? {{EXP_WIDTH{1'b0}}, 1'b1} : {1'b0, exp_a};
    assign eff_exp_b = exp_b_zero ? {{EXP_WIDTH{1'b0}}, 1'b1} : {1'b0, exp_b};

    assign sig_a_unaligned = {~exp_a_zero, frac_a, 3'b000};
    assign sig_b_unaligned = {~exp_b_zero, frac_b, 3'b000};

    always @* begin
        any_subnormal = (exp_a_zero && !frac_a_zero) ||
                        (exp_b_zero && !frac_b_zero);

        if ((eff_exp_a > eff_exp_b) ||
            ((eff_exp_a == eff_exp_b) &&
             (sig_a_unaligned >= sig_b_unaligned))) begin
            exp_big       = eff_exp_a;
            exp_small     = eff_exp_b;
            sign_big      = sign_a;
            sign_small    = sign_b;
            sig_big       = sig_a_unaligned;
            sig_small_pre = sig_b_unaligned;
        end else begin
            exp_big       = eff_exp_b;
            exp_small     = eff_exp_a;
            sign_big      = sign_b;
            sign_small    = sign_a;
            sig_big       = sig_b_unaligned;
            sig_small_pre = sig_a_unaligned;
        end

        shift_amt = exp_big - exp_small;
        sig_small = {SIG_WIDTH{1'b0}};
        sticky    = 1'b0;

        if (shift_amt >= SIG_WIDTH) begin
            sig_small[0] = |sig_small_pre;
        end else begin
            sig_small = sig_small_pre >> shift_amt;

            for (i = 0; i < SIG_WIDTH; i = i + 1) begin
                if (i < shift_amt)
                    sticky = sticky | sig_small_pre[i];
            end

            sig_small[0] = sig_small[0] | sticky;
        end

        sig_big_ext   = {1'b0, sig_big};
        sig_small_ext = {1'b0, sig_small};

        op_sub     = (sign_big != sign_small);
        add_result = sig_big_ext + sig_small_ext;
        sub_result = sig_big_ext - sig_small_ext;

        result_exp  = exp_big;
        result_mag  = {RAW_WIDTH{1'b0}};
        result_sign = sign_big;
        result_zero = 1'b0;

        if (!op_sub) begin
            result_mag  = add_result;
            result_sign = sign_big;
            result_zero = (add_result == {RAW_WIDTH{1'b0}});
        end else begin
            result_mag = sub_result;

            if (sub_result == {RAW_WIDTH{1'b0}}) begin
                result_zero = 1'b1;
                result_sign = (rnd_mode == 3'd3);
            end else begin
                result_zero = 1'b0;
                result_sign = sign_big;
            end
        end
    end

endmodule