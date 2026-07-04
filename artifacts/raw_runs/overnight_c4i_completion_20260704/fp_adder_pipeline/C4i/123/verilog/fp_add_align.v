module fp_add_align (
    input sign_a_in,
    input sign_b_in,
    input [7:0] exp_a,
    input [7:0] exp_b,
    input [26:0] mant_a,
    input [26:0] mant_b,
    input zero_a_in,
    input zero_b_in,
    input inf_a_in,
    input inf_b_in,
    input nan_a_in,
    input nan_b_in,
    output sign_a,
    output sign_b,
    output [7:0] exp_common,
    output [26:0] mant_a_aligned,
    output [26:0] mant_b_aligned,
    output zero_a,
    output zero_b,
    output inf_a,
    output inf_b,
    output nan_a,
    output nan_b
);

function [26:0] shift_right_sticky;
    input [26:0] value;
    input [7:0] shift;
    reg sticky;
    reg [26:0] shifted;
    begin
        if (shift == 8'd0) begin
            shift_right_sticky = value;
        end else if (shift >= 8'd27) begin
            shift_right_sticky = {26'd0, |value};
        end else begin
            sticky = |(value & ((27'd1 << shift) - 27'd1));
            shifted = value >> shift;
            shift_right_sticky = shifted | {26'd0, sticky};
        end
    end
endfunction

assign sign_a = sign_a_in;
assign sign_b = sign_b_in;

assign exp_common = (exp_a >= exp_b) ? exp_a : exp_b;

assign mant_a_aligned = (exp_a >= exp_b)
                      ? mant_a
                      : shift_right_sticky(mant_a, exp_b - exp_a);

assign mant_b_aligned = (exp_b >= exp_a)
                      ? mant_b
                      : shift_right_sticky(mant_b, exp_a - exp_b);

assign zero_a = zero_a_in;
assign zero_b = zero_b_in;
assign inf_a = inf_a_in;
assign inf_b = inf_b_in;
assign nan_a = nan_a_in;
assign nan_b = nan_b_in;

endmodule