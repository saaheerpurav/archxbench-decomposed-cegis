`timescale 1ns/1ps

module fpa_unpack_align #(
    parameter integer WIDTH = 32,
    parameter integer EXP_WIDTH = 8,
    parameter integer MANT_WIDTH = 23
)(
    input  [WIDTH-1:0]      a,
    input  [WIDTH-1:0]      b,

    output                  sign_a,
    output                  sign_b,
    output [EXP_WIDTH-1:0]  exp_a,
    output [EXP_WIDTH-1:0]  exp_b,
    output [MANT_WIDTH-1:0] frac_a,
    output [MANT_WIDTH-1:0] frac_b,

    output reg [EXP_WIDTH:0]    exp_big,
    output reg                  sign_big,
    output reg                  sign_small,
    output reg [MANT_WIDTH+3:0] sig_big,
    output reg [MANT_WIDTH+3:0] sig_small,

    output                  any_subnormal
);

    localparam integer SIG_WIDTH = MANT_WIDTH + 4;

    assign sign_a = a[WIDTH-1];
    assign sign_b = b[WIDTH-1];

    assign exp_a  = a[MANT_WIDTH +: EXP_WIDTH];
    assign exp_b  = b[MANT_WIDTH +: EXP_WIDTH];

    assign frac_a = a[MANT_WIDTH-1:0];
    assign frac_b = b[MANT_WIDTH-1:0];

    wire exp_a_is_zero = (exp_a == {EXP_WIDTH{1'b0}});
    wire exp_b_is_zero = (exp_b == {EXP_WIDTH{1'b0}});

    wire frac_a_is_zero = (frac_a == {MANT_WIDTH{1'b0}});
    wire frac_b_is_zero = (frac_b == {MANT_WIDTH{1'b0}});

    wire a_subnormal = exp_a_is_zero && !frac_a_is_zero;
    wire b_subnormal = exp_b_is_zero && !frac_b_is_zero;

    assign any_subnormal = a_subnormal || b_subnormal;

    wire [EXP_WIDTH:0] eff_exp_a =
        exp_a_is_zero ? {{EXP_WIDTH{1'b0}}, 1'b1} : {1'b0, exp_a};

    wire [EXP_WIDTH:0] eff_exp_b =
        exp_b_is_zero ? {{EXP_WIDTH{1'b0}}, 1'b1} : {1'b0, exp_b};

    wire [SIG_WIDTH-1:0] raw_sig_a = {~exp_a_is_zero, frac_a, 3'b000};
    wire [SIG_WIDTH-1:0] raw_sig_b = {~exp_b_is_zero, frac_b, 3'b000};

    reg [EXP_WIDTH:0]    exp_small;
    reg [EXP_WIDTH:0]    shift_amt;
    reg [SIG_WIDTH-1:0]  pre_big;
    reg [SIG_WIDTH-1:0]  pre_small;
    reg                  sticky;

    integer i;

    always @* begin
        if ((eff_exp_a > eff_exp_b) ||
            ((eff_exp_a == eff_exp_b) && (raw_sig_a >= raw_sig_b))) begin
            exp_big    = eff_exp_a;
            exp_small  = eff_exp_b;
            sign_big   = sign_a;
            sign_small = sign_b;
            pre_big    = raw_sig_a;
            pre_small  = raw_sig_b;
        end else begin
            exp_big    = eff_exp_b;
            exp_small  = eff_exp_a;
            sign_big   = sign_b;
            sign_small = sign_a;
            pre_big    = raw_sig_b;
            pre_small  = raw_sig_a;
        end

        shift_amt = exp_big - exp_small;

        sig_big   = pre_big;
        sig_small = {SIG_WIDTH{1'b0}};
        sticky    = 1'b0;

        if (shift_amt >= SIG_WIDTH) begin
            sig_small = {SIG_WIDTH{1'b0}};
            sig_small[0] = |pre_small;
        end else begin
            sig_small = pre_small >> shift_amt;

            for (i = 0; i < SIG_WIDTH; i = i + 1) begin
                if (i < shift_amt)
                    sticky = sticky | pre_small[i];
            end

            sig_small[0] = sig_small[0] | sticky;
        end
    end

endmodule