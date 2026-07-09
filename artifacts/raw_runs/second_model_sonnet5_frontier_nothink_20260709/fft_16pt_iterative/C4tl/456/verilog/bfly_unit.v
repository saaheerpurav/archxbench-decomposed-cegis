module bfly_unit #(
    parameter OUT_W   = 16,
    parameter COEFF_W = 16
) (
    input mode, // 0: FFT, 1: IFFT
    input signed [OUT_W-1:0] p_re_in,
    input signed [OUT_W-1:0] p_im_in,
    input signed [OUT_W-1:0] q_re_in,
    input signed [OUT_W-1:0] q_im_in,
    input signed [COEFF_W-1:0] cos_val,
    input signed [COEFF_W-1:0] sin_val,
    output signed [OUT_W-1:0] p_re_out,
    output signed [OUT_W-1:0] p_im_out,
    output signed [OUT_W-1:0] q_re_out,
    output signed [OUT_W-1:0] q_im_out
);
    // FFT mode: W = cos - j*sin
    // IFFT mode: W = cos + j*sin (conjugate) -> negate sin usage
    wire signed [COEFF_W-1:0] eff_sin;
    assign eff_sin = mode ? -sin_val : sin_val;

    // Twiddle multiply: (xr[q] + j*xi[q]) * (cos - j*eff_sin)
    // tr_real = (xr*cos + xi*eff_sin + 2^14) >> 15
    // tr_imag = (xi*cos - xr*eff_sin + 2^14) >> 15
    localparam PROD_W = OUT_W + COEFF_W + 2; // extra headroom for sum/rounding

    wire signed [PROD_W-1:0] mul_rc, mul_is, mul_ic, mul_rs;
    wire signed [PROD_W-1:0] sum_re, sum_im;
    wire signed [PROD_W-1:0] tr_real_full, tr_imag_full;
    wire signed [OUT_W-1:0]  tr_real, tr_imag;

    assign mul_rc = q_re_in * cos_val;
    assign mul_is = q_im_in * eff_sin;
    assign mul_ic = q_im_in * cos_val;
    assign mul_rs = q_re_in * eff_sin;

    assign sum_re = mul_rc + mul_is + (1 <<< 14);
    assign sum_im = mul_ic - mul_rs + (1 <<< 14);

    assign tr_real_full = sum_re >>> 15;
    assign tr_imag_full = sum_im >>> 15;

    // Take the low OUT_W bits (properly represents the rounded Q-format result,
    // since the true magnitude fits within OUT_W bits for valid FFT data ranges).
    assign tr_real = tr_real_full[OUT_W-1:0];
    assign tr_imag = tr_imag_full[OUT_W-1:0];

    assign p_re_out = p_re_in + tr_real;
    assign p_im_out = p_im_in + tr_imag;
    assign q_re_out = p_re_in - tr_real;
    assign q_im_out = p_im_in - tr_imag;

endmodule