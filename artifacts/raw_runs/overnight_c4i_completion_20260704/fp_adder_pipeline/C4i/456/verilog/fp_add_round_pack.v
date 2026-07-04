`timescale 1ns/1ps

module fp_add_round_pack (
    input sign,
    input [8:0] exp,
    input [26:0] sig,
    input zero,
    input a_sign,
    input b_sign,
    input a_zero,
    input b_zero,
    input a_inf,
    input b_inf,
    input a_nan,
    input b_nan,
    input exact_zero_inputs,
    output reg [31:0] result
);

reg [23:0] mant;
reg [24:0] mant_rounded;
reg [8:0] exp_rounded;
reg guard_bit;
reg round_bit;
reg sticky_bit;
reg increment;
reg final_sign;

always @* begin
    result = 32'h00000000;
    final_sign = sign;

    mant = 24'b0;
    mant_rounded = 25'b0;
    exp_rounded = 9'b0;
    guard_bit = 1'b0;
    round_bit = 1'b0;
    sticky_bit = 1'b0;
    increment = 1'b0;

    if (a_nan || b_nan) begin
        result = 32'h7FC00000;
    end else if (a_inf && b_inf && (a_sign != b_sign)) begin
        result = 32'h7FC00000;
    end else if (a_inf) begin
        result = {a_sign, 8'hFF, 23'b0};
    end else if (b_inf) begin
        result = {b_sign, 8'hFF, 23'b0};
    end else if (zero) begin
        if (exact_zero_inputs && a_sign && b_sign) begin
            result = 32'h80000000;
        end else begin
            result = 32'h00000000;
        end
    end else begin
        mant = sig[26:3];
        guard_bit = sig[2];
        round_bit = sig[1];
        sticky_bit = sig[0];

        increment = guard_bit && (round_bit || sticky_bit || mant[0]);

        mant_rounded = {1'b0, mant} + {24'b0, increment};
        exp_rounded = exp;

        if (mant_rounded[24]) begin
            mant_rounded = mant_rounded >> 1;
            exp_rounded = exp_rounded + 9'd1;
        end

        if (exp_rounded >= 9'd255) begin
            result = {final_sign, 8'hFF, 23'b0};
        end else if (exp_rounded == 9'd0) begin
            result = {final_sign, 8'h00, mant_rounded[22:0]};
        end else begin
            result = {final_sign, exp_rounded[7:0], mant_rounded[22:0]};
        end
    end
end

endmodule