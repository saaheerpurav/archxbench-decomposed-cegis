`timescale 1ns/1ps

module fp_adder_pipeline #(
    parameter LATENCY = 5
) (
    input clk,
    input rst,
    input [31:0] a,
    input [31:0] b,
    input add_sub,
    input valid_in,
    output [31:0] result,
    output valid_out
);

wire [31:0] b_eff = {b[31] ^ add_sub, b[30:0]};

wire s1_a_sign, s1_b_sign;
wire [7:0] s1_a_exp, s1_b_exp;
wire [26:0] s1_a_sig, s1_b_sig;
wire s1_a_zero, s1_b_zero, s1_a_inf, s1_b_inf, s1_a_nan, s1_b_nan;

fp_add_unpack u_unpack (
    .a(a),
    .b(b_eff),
    .a_sign(s1_a_sign),
    .b_sign(s1_b_sign),
    .a_exp(s1_a_exp),
    .b_exp(s1_b_exp),
    .a_sig(s1_a_sig),
    .b_sig(s1_b_sig),
    .a_zero(s1_a_zero),
    .b_zero(s1_b_zero),
    .a_inf(s1_a_inf),
    .b_inf(s1_b_inf),
    .a_nan(s1_a_nan),
    .b_nan(s1_b_nan)
);

reg r1_a_sign, r1_b_sign;
reg [7:0] r1_a_exp, r1_b_exp;
reg [26:0] r1_a_sig, r1_b_sig;
reg r1_a_zero, r1_b_zero, r1_a_inf, r1_b_inf, r1_a_nan, r1_b_nan;

wire s2_large_sign, s2_small_sign;
wire [7:0] s2_exp;
wire [26:0] s2_large_sig, s2_small_sig;
wire s2_exact_zero_inputs;

fp_add_align u_align (
    .a_sign(r1_a_sign),
    .b_sign(r1_b_sign),
    .a_exp(r1_a_exp),
    .b_exp(r1_b_exp),
    .a_sig(r1_a_sig),
    .b_sig(r1_b_sig),
    .a_zero(r1_a_zero),
    .b_zero(r1_b_zero),
    .large_sign(s2_large_sign),
    .small_sign(s2_small_sign),
    .common_exp(s2_exp),
    .large_sig(s2_large_sig),
    .small_sig(s2_small_sig),
    .exact_zero_inputs(s2_exact_zero_inputs)
);

reg r2_large_sign, r2_small_sign;
reg [7:0] r2_exp;
reg [26:0] r2_large_sig, r2_small_sig;
reg r2_a_sign, r2_b_sign;
reg r2_a_zero, r2_b_zero, r2_a_inf, r2_b_inf, r2_a_nan, r2_b_nan;
reg r2_exact_zero_inputs;

wire s3_sign;
wire [7:0] s3_exp;
wire [27:0] s3_sum;
wire s3_zero;

fp_add_execute u_execute (
    .large_sign(r2_large_sign),
    .small_sign(r2_small_sign),
    .common_exp(r2_exp),
    .large_sig(r2_large_sig),
    .small_sig(r2_small_sig),
    .result_sign(s3_sign),
    .result_exp(s3_exp),
    .sum(s3_sum),
    .sum_zero(s3_zero)
);

reg r3_sign;
reg [7:0] r3_exp;
reg [27:0] r3_sum;
reg r3_zero;
reg r3_a_sign, r3_b_sign;
reg r3_a_zero, r3_b_zero, r3_a_inf, r3_b_inf, r3_a_nan, r3_b_nan;
reg r3_exact_zero_inputs;

wire s4_sign;
wire [8:0] s4_exp;
wire [26:0] s4_sig;
wire s4_zero;

fp_add_normalize u_normalize (
    .in_sign(r3_sign),
    .in_exp(r3_exp),
    .in_sum(r3_sum),
    .in_zero(r3_zero),
    .out_sign(s4_sign),
    .out_exp(s4_exp),
    .out_sig(s4_sig),
    .out_zero(s4_zero)
);

reg r4_sign;
reg [8:0] r4_exp;
reg [26:0] r4_sig;
reg r4_zero;
reg r4_a_sign, r4_b_sign;
reg r4_a_zero, r4_b_zero, r4_a_inf, r4_b_inf, r4_a_nan, r4_b_nan;
reg r4_exact_zero_inputs;

wire [31:0] s5_result;

fp_add_round_pack u_round_pack (
    .sign(r4_sign),
    .exp(r4_exp),
    .sig(r4_sig),
    .zero(r4_zero),
    .a_sign(r4_a_sign),
    .b_sign(r4_b_sign),
    .a_zero(r4_a_zero),
    .b_zero(r4_b_zero),
    .a_inf(r4_a_inf),
    .b_inf(r4_b_inf),
    .a_nan(r4_a_nan),
    .b_nan(r4_b_nan),
    .exact_zero_inputs(r4_exact_zero_inputs),
    .result(s5_result)
);

reg [31:0] r5_result;
reg [LATENCY-1:0] valid_pipe;

assign result = r5_result;
assign valid_out = valid_pipe[LATENCY-1];

always @(posedge clk) begin
    if (rst) begin
        r1_a_sign <= 1'b0;
        r1_b_sign <= 1'b0;
        r1_a_exp <= 8'b0;
        r1_b_exp <= 8'b0;
        r1_a_sig <= 27'b0;
        r1_b_sig <= 27'b0;
        r1_a_zero <= 1'b0;
        r1_b_zero <= 1'b0;
        r1_a_inf <= 1'b0;
        r1_b_inf <= 1'b0;
        r1_a_nan <= 1'b0;
        r1_b_nan <= 1'b0;

        r2_large_sign <= 1'b0;
        r2_small_sign <= 1'b0;
        r2_exp <= 8'b0;
        r2_large_sig <= 27'b0;
        r2_small_sig <= 27'b0;
        r2_a_sign <= 1'b0;
        r2_b_sign <= 1'b0;
        r2_a_zero <= 1'b0;
        r2_b_zero <= 1'b0;
        r2_a_inf <= 1'b0;
        r2_b_inf <= 1'b0;
        r2_a_nan <= 1'b0;
        r2_b_nan <= 1'b0;
        r2_exact_zero_inputs <= 1'b0;

        r3_sign <= 1'b0;
        r3_exp <= 8'b0;
        r3_sum <= 28'b0;
        r3_zero <= 1'b0;
        r3_a_sign <= 1'b0;
        r3_b_sign <= 1'b0;
        r3_a_zero <= 1'b0;
        r3_b_zero <= 1'b0;
        r3_a_inf <= 1'b0;
        r3_b_inf <= 1'b0;
        r3_a_nan <= 1'b0;
        r3_b_nan <= 1'b0;
        r3_exact_zero_inputs <= 1'b0;

        r4_sign <= 1'b0;
        r4_exp <= 9'b0;
        r4_sig <= 27'b0;
        r4_zero <= 1'b0;
        r4_a_sign <= 1'b0;
        r4_b_sign <= 1'b0;
        r4_a_zero <= 1'b0;
        r4_b_zero <= 1'b0;
        r4_a_inf <= 1'b0;
        r4_b_inf <= 1'b0;
        r4_a_nan <= 1'b0;
        r4_b_nan <= 1'b0;
        r4_exact_zero_inputs <= 1'b0;

        r5_result <= 32'b0;
        valid_pipe <= {LATENCY{1'b0}};
    end else begin
        r1_a_sign <= s1_a_sign;
        r1_b_sign <= s1_b_sign;
        r1_a_exp <= s1_a_exp;
        r1_b_exp <= s1_b_exp;
        r1_a_sig <= s1_a_sig;
        r1_b_sig <= s1_b_sig;
        r1_a_zero <= s1_a_zero;
        r1_b_zero <= s1_b_zero;
        r1_a_inf <= s1_a_inf;
        r1_b_inf <= s1_b_inf;
        r1_a_nan <= s1_a_nan;
        r1_b_nan <= s1_b_nan;

        r2_large_sign <= s2_large_sign;
        r2_small_sign <= s2_small_sign;
        r2_exp <= s2_exp;
        r2_large_sig <= s2_large_sig;
        r2_small_sig <= s2_small_sig;
        r2_a_sign <= r1_a_sign;
        r2_b_sign <= r1_b_sign;
        r2_a_zero <= r1_a_zero;
        r2_b_zero <= r1_b_zero;
        r2_a_inf <= r1_a_inf;
        r2_b_inf <= r1_b_inf;
        r2_a_nan <= r1_a_nan;
        r2_b_nan <= r1_b_nan;
        r2_exact_zero_inputs <= s2_exact_zero_inputs;

        r3_sign <= s3_sign;
        r3_exp <= s3_exp;
        r3_sum <= s3_sum;
        r3_zero <= s3_zero;
        r3_a_sign <= r2_a_sign;
        r3_b_sign <= r2_b_sign;
        r3_a_zero <= r2_a_zero;
        r3_b_zero <= r2_b_zero;
        r3_a_inf <= r2_a_inf;
        r3_b_inf <= r2_b_inf;
        r3_a_nan <= r2_a_nan;
        r3_b_nan <= r2_b_nan;
        r3_exact_zero_inputs <= r2_exact_zero_inputs;

        r4_sign <= s4_sign;
        r4_exp <= s4_exp;
        r4_sig <= s4_sig;
        r4_zero <= s4_zero;
        r4_a_sign <= r3_a_sign;
        r4_b_sign <= r3_b_sign;
        r4_a_zero <= r3_a_zero;
        r4_b_zero <= r3_b_zero;
        r4_a_inf <= r3_a_inf;
        r4_b_inf <= r3_b_inf;
        r4_a_nan <= r3_a_nan;
        r4_b_nan <= r3_b_nan;
        r4_exact_zero_inputs <= r3_exact_zero_inputs;

        r5_result <= s5_result;
        valid_pipe <= {valid_pipe[LATENCY-2:0], valid_in};
    end
end

endmodule