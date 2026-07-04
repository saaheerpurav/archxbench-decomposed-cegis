`timescale 1ns/1ps

module fp_add_align (
    input a_sign,
    input b_sign,
    input [7:0] a_exp,
    input [7:0] b_exp,
    input [26:0] a_sig,
    input [26:0] b_sig,
    input a_zero,
    input b_zero,
    output reg large_sign,
    output reg small_sign,
    output reg [7:0] common_exp,
    output reg [26:0] large_sig,
    output reg [26:0] small_sig,
    output exact_zero_inputs
);

assign exact_zero_inputs = a_zero && b_zero;

function [26:0] shift_right_sticky;
    input [26:0] value;
    input [7:0] shift;
    reg sticky;
    reg [26:0] shifted;
    reg [26:0] mask;
    begin
        if (shift == 8'd0) begin
            shift_right_sticky = value;
        end else if (shift >= 8'd27) begin
            shift_right_sticky = {26'b0, |value};
        end else begin
            mask = (27'b1 << shift) - 27'b1;
            sticky = |(value & mask);
            shifted = value >> shift;
            shifted[0] = shifted[0] | sticky;
            shift_right_sticky = shifted;
        end
    end
endfunction

always @* begin
    if ((a_exp > b_exp) || ((a_exp == b_exp) && (a_sig >= b_sig))) begin
        large_sign = a_sign;
        small_sign = b_sign;
        common_exp = a_exp;
        large_sig = a_sig;
        small_sig = shift_right_sticky(b_sig, a_exp - b_exp);
    end else begin
        large_sign = b_sign;
        small_sign = a_sign;
        common_exp = b_exp;
        large_sig = b_sig;
        small_sig = shift_right_sticky(a_sig, b_exp - a_exp);
    end
end

endmodule