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

wire        s1_sa, s1_sb;
wire [7:0]  s1_ea, s1_eb;
wire [26:0] s1_ma, s1_mb;
wire        s1_za, s1_zb, s1_ia, s1_ib, s1_na, s1_nb;

fp_add_unpack u_unpack (
    .a(a), .b(b),
    .sign_a(s1_sa), .sign_b(s1_sb),
    .exp_a(s1_ea), .exp_b(s1_eb),
    .mant_a(s1_ma), .mant_b(s1_mb),
    .zero_a(s1_za), .zero_b(s1_zb),
    .inf_a(s1_ia), .inf_b(s1_ib),
    .nan_a(s1_na), .nan_b(s1_nb)
);

reg        r1_sa, r1_sb, r1_add_sub;
reg [7:0]  r1_ea, r1_eb;
reg [26:0] r1_ma, r1_mb;
reg        r1_za, r1_zb, r1_ia, r1_ib, r1_na, r1_nb;

wire        s2_sa, s2_sb;
wire [7:0]  s2_exp;
wire [26:0] s2_ma, s2_mb;
wire        s2_za, s2_zb, s2_ia, s2_ib, s2_na, s2_nb;

fp_add_align u_align (
    .sign_a_in(r1_sa), .sign_b_in(r1_sb),
    .exp_a(r1_ea), .exp_b(r1_eb),
    .mant_a(r1_ma), .mant_b(r1_mb),
    .zero_a_in(r1_za), .zero_b_in(r1_zb),
    .inf_a_in(r1_ia), .inf_b_in(r1_ib),
    .nan_a_in(r1_na), .nan_b_in(r1_nb),
    .sign_a(s2_sa), .sign_b(s2_sb),
    .exp_common(s2_exp),
    .mant_a_aligned(s2_ma), .mant_b_aligned(s2_mb),
    .zero_a(s2_za), .zero_b(s2_zb),
    .inf_a(s2_ia), .inf_b(s2_ib),
    .nan_a(s2_na), .nan_b(s2_nb)
);

reg        r2_sa, r2_sb, r2_add_sub;
reg [7:0]  r2_exp;
reg [26:0] r2_ma, r2_mb;
reg        r2_za, r2_zb, r2_ia, r2_ib, r2_na, r2_nb;

wire        s3_sign;
wire [7:0]  s3_exp;
wire [27:0] s3_mant;
wire        s3_zero;
wire        s3_ia, s3_ib, s3_na, s3_nb, s3_eff_sb;

fp_add_significand u_add (
    .sign_a(r2_sa), .sign_b(r2_sb),
    .add_sub(r2_add_sub),
    .exp_common(r2_exp),
    .mant_a(r2_ma), .mant_b(r2_mb),
    .zero_a(r2_za), .zero_b(r2_zb),
    .inf_a_in(r2_ia), .inf_b_in(r2_ib),
    .nan_a_in(r2_na), .nan_b_in(r2_nb),
    .result_sign(s3_sign),
    .result_exp(s3_exp),
    .result_mant(s3_mant),
    .result_zero(s3_zero),
    .inf_a(s3_ia), .inf_b(s3_ib),
    .nan_a(s3_na), .nan_b(s3_nb),
    .eff_sign_b(s3_eff_sb)
);

reg        r3_sign, r3_zero, r3_ia, r3_ib, r3_na, r3_nb, r3_eff_sb;
reg [7:0]  r3_exp;
reg [27:0] r3_mant;

wire        s4_sign, s4_zero, s4_overflow;
wire [8:0]  s4_exp;
wire [27:0] s4_mant;
wire        s4_ia, s4_ib, s4_na, s4_nb, s4_eff_sb;

fp_add_normalize u_norm (
    .sign_in(r3_sign),
    .exp_in(r3_exp),
    .mant_in(r3_mant),
    .zero_in(r3_zero),
    .inf_a_in(r3_ia), .inf_b_in(r3_ib),
    .nan_a_in(r3_na), .nan_b_in(r3_nb),
    .eff_sign_b_in(r3_eff_sb),
    .sign_out(s4_sign),
    .exp_out(s4_exp),
    .mant_out(s4_mant),
    .zero_out(s4_zero),
    .overflow_out(s4_overflow),
    .inf_a(s4_ia), .inf_b(s4_ib),
    .nan_a(s4_na), .nan_b(s4_nb),
    .eff_sign_b(s4_eff_sb)
);

reg        r4_sign, r4_zero, r4_overflow, r4_ia, r4_ib, r4_na, r4_nb, r4_eff_sb;
reg [8:0]  r4_exp;
reg [27:0] r4_mant;

wire [31:0] s5_result;

fp_add_round_pack u_pack (
    .sign_in(r4_sign),
    .exp_in(r4_exp),
    .mant_in(r4_mant),
    .zero_in(r4_zero),
    .overflow_in(r4_overflow),
    .inf_a(r4_ia), .inf_b(r4_ib),
    .nan_a(r4_na), .nan_b(r4_nb),
    .eff_sign_b(r4_eff_sb),
    .result(s5_result)
);

reg [31:0] result_reg;
reg [LATENCY-1:0] valid_pipe;
assign result = result_reg;
assign valid_out = valid_pipe[LATENCY-1];

integer i;
always @(posedge clk) begin
    if (rst) begin
        r1_sa <= 0; r1_sb <= 0; r1_add_sub <= 0; r1_ea <= 0; r1_eb <= 0; r1_ma <= 0; r1_mb <= 0;
        r1_za <= 0; r1_zb <= 0; r1_ia <= 0; r1_ib <= 0; r1_na <= 0; r1_nb <= 0;
        r2_sa <= 0; r2_sb <= 0; r2_add_sub <= 0; r2_exp <= 0; r2_ma <= 0; r2_mb <= 0;
        r2_za <= 0; r2_zb <= 0; r2_ia <= 0; r2_ib <= 0; r2_na <= 0; r2_nb <= 0;
        r3_sign <= 0; r3_exp <= 0; r3_mant <= 0; r3_zero <= 0; r3_ia <= 0; r3_ib <= 0; r3_na <= 0; r3_nb <= 0; r3_eff_sb <= 0;
        r4_sign <= 0; r4_exp <= 0; r4_mant <= 0; r4_zero <= 0; r4_overflow <= 0; r4_ia <= 0; r4_ib <= 0; r4_na <= 0; r4_nb <= 0; r4_eff_sb <= 0;
        result_reg <= 0;
        valid_pipe <= 0;
    end else begin
        valid_pipe <= {valid_pipe[LATENCY-2:0], valid_in};

        r1_sa <= s1_sa; r1_sb <= s1_sb; r1_add_sub <= add_sub; r1_ea <= s1_ea; r1_eb <= s1_eb; r1_ma <= s1_ma; r1_mb <= s1_mb;
        r1_za <= s1_za; r1_zb <= s1_zb; r1_ia <= s1_ia; r1_ib <= s1_ib; r1_na <= s1_na; r1_nb <= s1_nb;

        r2_sa <= s2_sa; r2_sb <= s2_sb; r2_add_sub <= r1_add_sub; r2_exp <= s2_exp; r2_ma <= s2_ma; r2_mb <= s2_mb;
        r2_za <= s2_za; r2_zb <= s2_zb; r2_ia <= s2_ia; r2_ib <= s2_ib; r2_na <= s2_na; r2_nb <= s2_nb;

        r3_sign <= s3_sign; r3_exp <= s3_exp; r3_mant <= s3_mant; r3_zero <= s3_zero;
        r3_ia <= s3_ia; r3_ib <= s3_ib; r3_na <= s3_na; r3_nb <= s3_nb; r3_eff_sb <= s3_eff_sb;

        r4_sign <= s4_sign; r4_exp <= s4_exp; r4_mant <= s4_mant; r4_zero <= s4_zero; r4_overflow <= s4_overflow;
        r4_ia <= s4_ia; r4_ib <= s4_ib; r4_na <= s4_na; r4_nb <= s4_nb; r4_eff_sb <= s4_eff_sb;

        result_reg <= s5_result;
    end
end

endmodule