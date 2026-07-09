module butterfly_unit #(
    parameter OUT_W = 16,
    parameter COEFF_W = 16
) (
    input mode, // 0: FFT, 1: IFFT
    input signed [OUT_W-1:0] p_real,
    input signed [OUT_W-1:0] p_imag,
    input signed [OUT_W-1:0] q_real,
    input signed [OUT_W-1:0] q_imag,
    input signed [COEFF_W-1:0] cos_val,
    input signed [COEFF_W-1:0] sin_val,
    output signed [OUT_W-1:0] p_real_out,
    output signed [OUT_W-1:0] p_imag_out,
    output signed [OUT_W-1:0] q_real_out,
    output signed [OUT_W-1:0] q_imag_out
);

    // effective sin: for IFFT, twiddle is conjugated -> negate imag twiddle coefficient
    wire signed [COEFF_W-1:0] eff_sin;
    assign eff_sin = mode ? (-sin_val) : sin_val;

    // Wide product terms (avoid overflow: OUT_W + COEFF_W bits, plus headroom for sum)
    wire signed [OUT_W+COEFF_W:0] mul_r_cos, mul_i_sin, mul_i_cos, mul_r_sin;
    assign mul_r_cos = q_real * cos_val;
    assign mul_i_sin = q_imag * eff_sin;
    assign mul_i_cos = q_imag * cos_val;
    assign mul_r_sin = q_real * eff_sin;

    // Q1.15 rounding: add 2^14 before arithmetic right shift by 15
    wire signed [OUT_W+COEFF_W:0] sum_r, sum_i;
    assign sum_r = mul_r_cos + mul_i_sin + (1 <<< 14);
    assign sum_i = mul_i_cos - mul_r_sin + (1 <<< 14);

    wire signed [OUT_W+COEFF_W:0] tr_real_full, tr_imag_full;
    assign tr_real_full = sum_r >>> 15;
    assign tr_imag_full = sum_i >>> 15;

    // Truncate/assign into OUT_W-wide signed values (standard Verilog truncation)
    wire signed [OUT_W-1:0] tr_real, tr_imag;
    assign tr_real = tr_real_full[OUT_W-1:0];
    assign tr_imag = tr_imag_full[OUT_W-1:0];

    // Butterfly combine: t = q*W ; p' = p+t ; q' = p-t
    assign p_real_out = p_real + tr_real;
    assign p_imag_out = p_imag + tr_imag;
    assign q_real_out = p_real - tr_real;
    assign q_imag_out = p_imag - tr_imag;

endmodule