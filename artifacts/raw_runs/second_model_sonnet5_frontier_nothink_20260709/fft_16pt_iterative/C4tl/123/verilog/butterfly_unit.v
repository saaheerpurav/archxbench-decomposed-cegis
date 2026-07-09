module butterfly_unit #(
    parameter OUT_W = 16,
    parameter COEFF_W = 16
) (
    input  signed [OUT_W-1:0] p_real,
    input  signed [OUT_W-1:0] p_imag,
    input  signed [OUT_W-1:0] q_real,
    input  signed [OUT_W-1:0] q_imag,
    input  signed [COEFF_W-1:0] tw_cos,
    input  signed [COEFF_W-1:0] tw_sin,
    output signed [OUT_W-1:0] p_real_out,
    output signed [OUT_W-1:0] p_imag_out,
    output signed [OUT_W-1:0] q_real_out,
    output signed [OUT_W-1:0] q_imag_out
);

    // Twiddle multiply: (xr + j*xi) * (cos - j*sin)
    // tr_real = (xr*cos + xi*sin + 2^14) >>> 15
    // tr_imag = (xi*cos - xr*sin + 2^14) >>> 15
    wire signed [OUT_W+COEFF_W-1:0] mul_rc = q_real * tw_cos;
    wire signed [OUT_W+COEFF_W-1:0] mul_is = q_imag * tw_sin;
    wire signed [OUT_W+COEFF_W-1:0] mul_ic = q_imag * tw_cos;
    wire signed [OUT_W+COEFF_W-1:0] mul_rs = q_real * tw_sin;

    wire signed [OUT_W+COEFF_W-1:0] sum_real_full = mul_rc + mul_is + (1 <<< 14);
    wire signed [OUT_W+COEFF_W-1:0] sum_imag_full = mul_ic - mul_rs + (1 <<< 14);

    wire signed [OUT_W+COEFF_W-1:0] tr_real_full = sum_real_full >>> 15;
    wire signed [OUT_W+COEFF_W-1:0] tr_imag_full = sum_imag_full >>> 15;

    // Truncate to OUT_W bits (value is guaranteed to fit since |twiddle| <= 1.0)
    wire signed [OUT_W-1:0] tr_real = tr_real_full[OUT_W-1:0];
    wire signed [OUT_W-1:0] tr_imag = tr_imag_full[OUT_W-1:0];

    assign p_real_out = p_real + tr_real;
    assign p_imag_out = p_imag + tr_imag;
    assign q_real_out = p_real - tr_real;
    assign q_imag_out = p_imag - tr_imag;

endmodule