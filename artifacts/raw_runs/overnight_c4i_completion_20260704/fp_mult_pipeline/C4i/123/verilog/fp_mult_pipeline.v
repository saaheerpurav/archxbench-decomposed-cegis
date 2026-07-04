`timescale 1ns/1ps

module fp_mult_pipeline #(
    parameter LATENCY = 5
) (
    input clk,
    input rst,
    input [31:0] a,
    input [31:0] b,
    input valid_in,
    output reg [31:0] result,
    output reg valid_out
);

wire s1_sign_w, s1_a_zero_w, s1_b_zero_w, s1_a_inf_w, s1_b_inf_w, s1_a_nan_w, s1_b_nan_w;
wire [7:0] s1_a_exp_w, s1_b_exp_w;
wire [23:0] s1_a_mant_w, s1_b_mant_w;

fp_mult_unpack u_unpack (
    .a(a),
    .b(b),
    .sign(s1_sign_w),
    .a_exp_eff(s1_a_exp_w),
    .b_exp_eff(s1_b_exp_w),
    .a_mant(s1_a_mant_w),
    .b_mant(s1_b_mant_w),
    .a_zero(s1_a_zero_w),
    .b_zero(s1_b_zero_w),
    .a_inf(s1_a_inf_w),
    .b_inf(s1_b_inf_w),
    .a_nan(s1_a_nan_w),
    .b_nan(s1_b_nan_w)
);

reg s1_valid;
reg s1_sign, s1_a_zero, s1_b_zero, s1_a_inf, s1_b_inf, s1_a_nan, s1_b_nan;
reg [7:0] s1_a_exp, s1_b_exp;
reg [23:0] s1_a_mant, s1_b_mant;

wire [47:0] s2_product_w;
wire signed [10:0] s2_exp_w;

fp_mult_multiply u_multiply (
    .a_exp_eff(s1_a_exp),
    .b_exp_eff(s1_b_exp),
    .a_mant(s1_a_mant),
    .b_mant(s1_b_mant),
    .product(s2_product_w),
    .exp_unbiased(s2_exp_w)
);

reg s2_valid;
reg s2_sign, s2_a_zero, s2_b_zero, s2_a_inf, s2_b_inf, s2_a_nan, s2_b_nan;
reg [47:0] s2_product;
reg signed [10:0] s2_exp;

wire [23:0] s3_mant_w;
wire signed [10:0] s3_exp_w;
wire s3_guard_w, s3_round_w, s3_sticky_w;

fp_mult_normalize u_normalize (
    .product(s2_product),
    .exp_in(s2_exp),
    .mantissa(s3_mant_w),
    .exp_out(s3_exp_w),
    .guard_bit(s3_guard_w),
    .round_bit(s3_round_w),
    .sticky_bit(s3_sticky_w)
);

reg s3_valid;
reg s3_sign, s3_a_zero, s3_b_zero, s3_a_inf, s3_b_inf, s3_a_nan, s3_b_nan;
reg [23:0] s3_mant;
reg signed [10:0] s3_exp;
reg s3_guard, s3_round, s3_sticky;

wire [22:0] s4_frac_w;
wire signed [10:0] s4_exp_w;

fp_mult_round u_round (
    .mantissa(s3_mant),
    .exp_in(s3_exp),
    .guard_bit(s3_guard),
    .round_bit(s3_round),
    .sticky_bit(s3_sticky),
    .frac(s4_frac_w),
    .exp_out(s4_exp_w)
);

reg s4_valid;
reg s4_sign, s4_a_zero, s4_b_zero, s4_a_inf, s4_b_inf, s4_a_nan, s4_b_nan;
reg [22:0] s4_frac;
reg signed [10:0] s4_exp;

wire [31:0] s5_result_w;

fp_mult_pack u_pack (
    .sign(s4_sign),
    .exp_in(s4_exp),
    .frac(s4_frac),
    .a_zero(s4_a_zero),
    .b_zero(s4_b_zero),
    .a_inf(s4_a_inf),
    .b_inf(s4_b_inf),
    .a_nan(s4_a_nan),
    .b_nan(s4_b_nan),
    .result(s5_result_w)
);

always @(posedge clk) begin
    if (rst) begin
        s1_valid <= 1'b0;
        s1_sign <= 1'b0;
        s1_a_exp <= 8'b0;
        s1_b_exp <= 8'b0;
        s1_a_mant <= 24'b0;
        s1_b_mant <= 24'b0;
        s1_a_zero <= 1'b0;
        s1_b_zero <= 1'b0;
        s1_a_inf <= 1'b0;
        s1_b_inf <= 1'b0;
        s1_a_nan <= 1'b0;
        s1_b_nan <= 1'b0;

        s2_valid <= 1'b0;
        s2_sign <= 1'b0;
        s2_product <= 48'b0;
        s2_exp <= 11'sd0;
        s2_a_zero <= 1'b0;
        s2_b_zero <= 1'b0;
        s2_a_inf <= 1'b0;
        s2_b_inf <= 1'b0;
        s2_a_nan <= 1'b0;
        s2_b_nan <= 1'b0;

        s3_valid <= 1'b0;
        s3_sign <= 1'b0;
        s3_mant <= 24'b0;
        s3_exp <= 11'sd0;
        s3_guard <= 1'b0;
        s3_round <= 1'b0;
        s3_sticky <= 1'b0;
        s3_a_zero <= 1'b0;
        s3_b_zero <= 1'b0;
        s3_a_inf <= 1'b0;
        s3_b_inf <= 1'b0;
        s3_a_nan <= 1'b0;
        s3_b_nan <= 1'b0;

        s4_valid <= 1'b0;
        s4_sign <= 1'b0;
        s4_frac <= 23'b0;
        s4_exp <= 11'sd0;
        s4_a_zero <= 1'b0;
        s4_b_zero <= 1'b0;
        s4_a_inf <= 1'b0;
        s4_b_inf <= 1'b0;
        s4_a_nan <= 1'b0;
        s4_b_nan <= 1'b0;

        result <= 32'b0;
        valid_out <= 1'b0;
    end else begin
        s1_valid <= valid_in;
        s1_sign <= s1_sign_w;
        s1_a_exp <= s1_a_exp_w;
        s1_b_exp <= s1_b_exp_w;
        s1_a_mant <= s1_a_mant_w;
        s1_b_mant <= s1_b_mant_w;
        s1_a_zero <= s1_a_zero_w;
        s1_b_zero <= s1_b_zero_w;
        s1_a_inf <= s1_a_inf_w;
        s1_b_inf <= s1_b_inf_w;
        s1_a_nan <= s1_a_nan_w;
        s1_b_nan <= s1_b_nan_w;

        s2_valid <= s1_valid;
        s2_sign <= s1_sign;
        s2_product <= s2_product_w;
        s2_exp <= s2_exp_w;
        s2_a_zero <= s1_a_zero;
        s2_b_zero <= s1_b_zero;
        s2_a_inf <= s1_a_inf;
        s2_b_inf <= s1_b_inf;
        s2_a_nan <= s1_a_nan;
        s2_b_nan <= s1_b_nan;

        s3_valid <= s2_valid;
        s3_sign <= s2_sign;
        s3_mant <= s3_mant_w;
        s3_exp <= s3_exp_w;
        s3_guard <= s3_guard_w;
        s3_round <= s3_round_w;
        s3_sticky <= s3_sticky_w;
        s3_a_zero <= s2_a_zero;
        s3_b_zero <= s2_b_zero;
        s3_a_inf <= s2_a_inf;
        s3_b_inf <= s2_b_inf;
        s3_a_nan <= s2_a_nan;
        s3_b_nan <= s2_b_nan;

        s4_valid <= s3_valid;
        s4_sign <= s3_sign;
        s4_frac <= s4_frac_w;
        s4_exp <= s4_exp_w;
        s4_a_zero <= s3_a_zero;
        s4_b_zero <= s3_b_zero;
        s4_a_inf <= s3_a_inf;
        s4_b_inf <= s3_b_inf;
        s4_a_nan <= s3_a_nan;
        s4_b_nan <= s3_b_nan;

        valid_out <= s4_valid;
        if (s4_valid)
            result <= s5_result_w;
    end
end

endmodule