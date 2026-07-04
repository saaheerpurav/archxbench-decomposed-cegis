`timescale 1ns/1ps

module fp_mult_pipeline #(
    parameter LATENCY = 5
) (
    input clk,
    input rst,
    input [31:0] a,
    input [31:0] b,
    input valid_in,
    output [31:0] result,
    output valid_out
);

localparam EXTRA_LATENCY = (LATENCY > 5) ? (LATENCY - 5) : 0;

wire        s1_sign_w;
wire [7:0]  s1_exp_a_w, s1_exp_b_w;
wire [23:0] s1_mant_a_w, s1_mant_b_w;
wire        s1_zero_a_w, s1_zero_b_w;
wire        s1_inf_a_w, s1_inf_b_w;
wire        s1_nan_a_w, s1_nan_b_w;
wire        s1_sub_a_w, s1_sub_b_w;

fp_mult_unpack u_unpack (
    .a(a),
    .b(b),
    .sign(s1_sign_w),
    .exp_a(s1_exp_a_w),
    .exp_b(s1_exp_b_w),
    .mant_a(s1_mant_a_w),
    .mant_b(s1_mant_b_w),
    .zero_a(s1_zero_a_w),
    .zero_b(s1_zero_b_w),
    .inf_a(s1_inf_a_w),
    .inf_b(s1_inf_b_w),
    .nan_a(s1_nan_a_w),
    .nan_b(s1_nan_b_w),
    .sub_a(s1_sub_a_w),
    .sub_b(s1_sub_b_w)
);

reg        s1_sign;
reg [7:0]  s1_exp_a, s1_exp_b;
reg [23:0] s1_mant_a, s1_mant_b;
reg        s1_zero_a, s1_zero_b;
reg        s1_inf_a, s1_inf_b;
reg        s1_nan_a, s1_nan_b;
reg        s1_sub_a, s1_sub_b;

wire [47:0] s2_product_w;
wire signed [10:0] s2_exp_w;

fp_mult_exp_product u_exp_product (
    .exp_a(s1_exp_a),
    .exp_b(s1_exp_b),
    .mant_a(s1_mant_a),
    .mant_b(s1_mant_b),
    .product(s2_product_w),
    .exp_unbiased(s2_exp_w)
);

reg        s2_sign;
reg [47:0] s2_product;
reg signed [10:0] s2_exp;
reg        s2_zero_a, s2_zero_b;
reg        s2_inf_a, s2_inf_b;
reg        s2_nan_a, s2_nan_b;

wire signed [10:0] s3_exp_w;
wire [23:0] s3_mant_w;
wire        s3_guard_w, s3_round_w, s3_sticky_w;

fp_mult_normalize u_normalize (
    .product(s2_product),
    .exp_in(s2_exp),
    .exp_norm(s3_exp_w),
    .mant_norm(s3_mant_w),
    .guard_bit(s3_guard_w),
    .round_bit(s3_round_w),
    .sticky_bit(s3_sticky_w)
);

reg        s3_sign;
reg signed [10:0] s3_exp;
reg [23:0] s3_mant;
reg        s3_guard, s3_round, s3_sticky;
reg        s3_zero_a, s3_zero_b;
reg        s3_inf_a, s3_inf_b;
reg        s3_nan_a, s3_nan_b;

wire signed [10:0] s4_exp_w;
wire [22:0] s4_frac_w;

fp_mult_round u_round (
    .exp_in(s3_exp),
    .mant_in(s3_mant),
    .guard_bit(s3_guard),
    .round_bit(s3_round),
    .sticky_bit(s3_sticky),
    .exp_out(s4_exp_w),
    .frac_out(s4_frac_w)
);

reg        s4_sign;
reg signed [10:0] s4_exp;
reg [22:0] s4_frac;
reg        s4_zero_a, s4_zero_b;
reg        s4_inf_a, s4_inf_b;
reg        s4_nan_a, s4_nan_b;

wire [31:0] s5_result_w;

fp_mult_pack u_pack (
    .sign(s4_sign),
    .exp_in(s4_exp),
    .frac_in(s4_frac),
    .zero_a(s4_zero_a),
    .zero_b(s4_zero_b),
    .inf_a(s4_inf_a),
    .inf_b(s4_inf_b),
    .nan_a(s4_nan_a),
    .nan_b(s4_nan_b),
    .result(s5_result_w)
);

reg [31:0] result_reg;
reg [LATENCY-1:0] valid_pipe;

generate
if (EXTRA_LATENCY > 0) begin : g_extra_latency
    reg [31:0] result_delay [0:EXTRA_LATENCY-1];
    integer i;

    always @(posedge clk) begin
        if (rst) begin
            for (i = 0; i < EXTRA_LATENCY; i = i + 1)
                result_delay[i] <= 32'b0;
        end else begin
            result_delay[0] <= result_reg;
            for (i = 1; i < EXTRA_LATENCY; i = i + 1)
                result_delay[i] <= result_delay[i-1];
        end
    end

    assign result = result_delay[EXTRA_LATENCY-1];
end else begin : g_no_extra_latency
    assign result = result_reg;
end
endgenerate

assign valid_out = valid_pipe[LATENCY-1];

always @(posedge clk) begin
    if (rst) begin
        valid_pipe <= {LATENCY{1'b0}};

        s1_sign <= 1'b0;
        s1_exp_a <= 8'b0;
        s1_exp_b <= 8'b0;
        s1_mant_a <= 24'b0;
        s1_mant_b <= 24'b0;
        s1_zero_a <= 1'b0;
        s1_zero_b <= 1'b0;
        s1_inf_a <= 1'b0;
        s1_inf_b <= 1'b0;
        s1_nan_a <= 1'b0;
        s1_nan_b <= 1'b0;
        s1_sub_a <= 1'b0;
        s1_sub_b <= 1'b0;

        s2_sign <= 1'b0;
        s2_product <= 48'b0;
        s2_exp <= 11'sd0;
        s2_zero_a <= 1'b0;
        s2_zero_b <= 1'b0;
        s2_inf_a <= 1'b0;
        s2_inf_b <= 1'b0;
        s2_nan_a <= 1'b0;
        s2_nan_b <= 1'b0;

        s3_sign <= 1'b0;
        s3_exp <= 11'sd0;
        s3_mant <= 24'b0;
        s3_guard <= 1'b0;
        s3_round <= 1'b0;
        s3_sticky <= 1'b0;
        s3_zero_a <= 1'b0;
        s3_zero_b <= 1'b0;
        s3_inf_a <= 1'b0;
        s3_inf_b <= 1'b0;
        s3_nan_a <= 1'b0;
        s3_nan_b <= 1'b0;

        s4_sign <= 1'b0;
        s4_exp <= 11'sd0;
        s4_frac <= 23'b0;
        s4_zero_a <= 1'b0;
        s4_zero_b <= 1'b0;
        s4_inf_a <= 1'b0;
        s4_inf_b <= 1'b0;
        s4_nan_a <= 1'b0;
        s4_nan_b <= 1'b0;

        result_reg <= 32'b0;
    end else begin
        valid_pipe <= {valid_pipe[LATENCY-2:0], valid_in};

        s1_sign <= s1_sign_w;
        s1_exp_a <= s1_exp_a_w;
        s1_exp_b <= s1_exp_b_w;
        s1_mant_a <= s1_mant_a_w;
        s1_mant_b <= s1_mant_b_w;
        s1_zero_a <= s1_zero_a_w;
        s1_zero_b <= s1_zero_b_w;
        s1_inf_a <= s1_inf_a_w;
        s1_inf_b <= s1_inf_b_w;
        s1_nan_a <= s1_nan_a_w;
        s1_nan_b <= s1_nan_b_w;
        s1_sub_a <= s1_sub_a_w;
        s1_sub_b <= s1_sub_b_w;

        s2_sign <= s1_sign;
        s2_product <= s2_product_w;
        s2_exp <= s2_exp_w;
        s2_zero_a <= s1_zero_a;
        s2_zero_b <= s1_zero_b;
        s2_inf_a <= s1_inf_a;
        s2_inf_b <= s1_inf_b;
        s2_nan_a <= s1_nan_a;
        s2_nan_b <= s1_nan_b;

        s3_sign <= s2_sign;
        s3_exp <= s3_exp_w;
        s3_mant <= s3_mant_w;
        s3_guard <= s3_guard_w;
        s3_round <= s3_round_w;
        s3_sticky <= s3_sticky_w;
        s3_zero_a <= s2_zero_a;
        s3_zero_b <= s2_zero_b;
        s3_inf_a <= s2_inf_a;
        s3_inf_b <= s2_inf_b;
        s3_nan_a <= s2_nan_a;
        s3_nan_b <= s2_nan_b;

        s4_sign <= s3_sign;
        s4_exp <= s4_exp_w;
        s4_frac <= s4_frac_w;
        s4_zero_a <= s3_zero_a;
        s4_zero_b <= s3_zero_b;
        s4_inf_a <= s3_inf_a;
        s4_inf_b <= s3_inf_b;
        s4_nan_a <= s3_nan_a;
        s4_nan_b <= s3_nan_b;

        result_reg <= s5_result_w;
    end
end

endmodule