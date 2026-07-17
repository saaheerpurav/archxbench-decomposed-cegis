`timescale 1ns/1ps

module floating_point_adder #(
    parameter WIDTH = 32
)(
    input clk,
    input rst,
    input [WIDTH-1:0] a,
    input [WIDTH-1:0] b,
    input [2:0] rnd_mode,
    output reg [WIDTH-1:0] sum,
    output reg [2:0] exception_flags
);
    wire sign_a, sign_b;
    wire [7:0] exp_a, exp_b;
    wire [22:0] frac_a, frac_b;
    wire zero_a, zero_b, inf_a, inf_b, nan_a, nan_b, denorm_a, denorm_b;

    wire special_valid;
    wire [31:0] special_sum;
    wire [2:0] special_flags;

    wire align_sign;
    wire [8:0] align_exp;
    wire [27:0] align_mag;
    wire align_zero;

    wire [31:0] normal_sum;
    wire [2:0] normal_flags;

    fpa_unpack u_unpack_a (
        .in(a[31:0]),
        .sign(sign_a),
        .exp(exp_a),
        .frac(frac_a),
        .is_zero(zero_a),
        .is_inf(inf_a),
        .is_nan(nan_a),
        .is_denorm(denorm_a)
    );

    fpa_unpack u_unpack_b (
        .in(b[31:0]),
        .sign(sign_b),
        .exp(exp_b),
        .frac(frac_b),
        .is_zero(zero_b),
        .is_inf(inf_b),
        .is_nan(nan_b),
        .is_denorm(denorm_b)
    );

    fpa_special_cases u_special (
        .a(a[31:0]),
        .b(b[31:0]),
        .rnd_mode(rnd_mode),
        .sign_a(sign_a),
        .sign_b(sign_b),
        .zero_a(zero_a),
        .zero_b(zero_b),
        .inf_a(inf_a),
        .inf_b(inf_b),
        .nan_a(nan_a),
        .nan_b(nan_b),
        .special_valid(special_valid),
        .special_sum(special_sum),
        .special_flags(special_flags)
    );

    fpa_align_add u_align_add (
        .sign_a(sign_a),
        .sign_b(sign_b),
        .exp_a(exp_a),
        .exp_b(exp_b),
        .frac_a(frac_a),
        .frac_b(frac_b),
        .result_sign(align_sign),
        .result_exp(align_exp),
        .result_mag(align_mag),
        .result_zero(align_zero)
    );

    fpa_normalize_round u_norm_round (
        .sign_in(align_sign),
        .exp_in(align_exp),
        .mag_in(align_mag),
        .zero_in(align_zero),
        .rnd_mode(rnd_mode),
        .underflow_hint(denorm_a | denorm_b),
        .sum_out(normal_sum),
        .flags_out(normal_flags)
    );

    always @(*) begin
        if (rst) begin
            sum = {WIDTH{1'b0}};
            exception_flags = 3'b000;
        end else if (special_valid) begin
            sum = special_sum;
            exception_flags = special_flags;
        end else begin
            sum = normal_sum;
            exception_flags = normal_flags;
        end
    end
endmodule