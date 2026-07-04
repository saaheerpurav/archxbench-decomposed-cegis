`timescale 1ns/1ps

module fp_mult_pack (
    input sign,
    input signed [10:0] exp_in,
    input [22:0] frac,
    input a_zero,
    input b_zero,
    input a_inf,
    input b_inf,
    input a_nan,
    input b_nan,
    output reg [31:0] result
);

localparam [7:0] MAX_EXP = 8'hff;
localparam [22:0] ZERO_FRAC = 23'h000000;
localparam [31:0] CANONICAL_NAN = 32'h7fc00000;

always @* begin
    if (a_nan || b_nan || (a_zero && b_inf) || (a_inf && b_zero)) begin
        result = CANONICAL_NAN;
    end else if (a_inf || b_inf) begin
        result = {sign, MAX_EXP, ZERO_FRAC};
    end else if (a_zero || b_zero) begin
        result = {sign, 31'h00000000};
    end else if (exp_in >= 11'sd255) begin
        result = {sign, MAX_EXP, ZERO_FRAC};
    end else if (exp_in <= 11'sd0) begin
        result = {sign, 31'h00000000};
    end else begin
        result = {sign, exp_in[7:0], frac};
    end
end

endmodule