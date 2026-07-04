module fp_add_significand (
    input sign_a,
    input sign_b,
    input add_sub,
    input [7:0] exp_common,
    input [26:0] mant_a,
    input [26:0] mant_b,
    input zero_a,
    input zero_b,
    input inf_a_in,
    input inf_b_in,
    input nan_a_in,
    input nan_b_in,
    output reg result_sign,
    output [7:0] result_exp,
    output reg [27:0] result_mant,
    output result_zero,
    output inf_a,
    output inf_b,
    output nan_a,
    output nan_b,
    output eff_sign_b
);

assign eff_sign_b = sign_b ^ add_sub;

assign result_exp = exp_common;
assign result_zero = (result_mant == 28'd0);

assign inf_a = inf_a_in;
assign inf_b = inf_b_in;
assign nan_a = nan_a_in;
assign nan_b = nan_b_in;

always @* begin
    result_sign = 1'b0;
    result_mant = 28'd0;

    if (nan_a_in || nan_b_in) begin
        result_sign = 1'b0;
        result_mant = 28'd0;
    end else if (zero_a && zero_b) begin
        result_sign = sign_a & eff_sign_b;
        result_mant = 28'd0;
    end else if (zero_a) begin
        result_sign = eff_sign_b;
        result_mant = {1'b0, mant_b};
    end else if (zero_b) begin
        result_sign = sign_a;
        result_mant = {1'b0, mant_a};
    end else if (sign_a == eff_sign_b) begin
        result_sign = sign_a;
        result_mant = {1'b0, mant_a} + {1'b0, mant_b};
    end else if (mant_a > mant_b) begin
        result_sign = sign_a;
        result_mant = {1'b0, mant_a} - {1'b0, mant_b};
    end else if (mant_b > mant_a) begin
        result_sign = eff_sign_b;
        result_mant = {1'b0, mant_b} - {1'b0, mant_a};
    end else begin
        result_sign = 1'b0;
        result_mant = 28'd0;
    end
end

endmodule