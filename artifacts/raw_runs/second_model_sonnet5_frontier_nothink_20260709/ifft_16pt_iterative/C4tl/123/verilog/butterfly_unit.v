`timescale 1ns/1ps

// Combinational radix-2 DIT butterfly with complex twiddle rotation.
// Applies Q1.15 rounding multiply as specified.
//
// IN_W  : bit width of p/q inputs
// OUT_W : bit width of p/q outputs (must be >= IN_W+1 to avoid overflow
//         from the p+t / p-t addition/subtraction bit growth)
// COEFF_W: bit width of twiddle coefficients (Q1.15, COEFF_W=16)
module butterfly_unit #(
    parameter DATA_W  = 16,          // legacy name: input width
    parameter COEFF_W = 16,
    parameter IN_W    = DATA_W,
    parameter OUT_W   = DATA_W + 1   // default: grow by 1 bit per stage
) (
    input  signed [IN_W-1:0]    p_re_in,
    input  signed [IN_W-1:0]    p_im_in,
    input  signed [IN_W-1:0]    q_re_in,
    input  signed [IN_W-1:0]    q_im_in,
    input  signed [COEFF_W-1:0] cos_val,
    input  signed [COEFF_W-1:0] sin_val,
    output signed [OUT_W-1:0]   p_re_out,
    output signed [OUT_W-1:0]   p_im_out,
    output signed [OUT_W-1:0]   q_re_out,
    output signed [OUT_W-1:0]   q_im_out
);

    // Wide product accumulators
    localparam MUL_W = IN_W + COEFF_W + 2;

    wire signed [MUL_W-1:0] mul_re_cos = q_re_in * cos_val;
    wire signed [MUL_W-1:0] mul_im_sin = q_im_in * sin_val;
    wire signed [MUL_W-1:0] mul_re_sin = q_re_in * sin_val;
    wire signed [MUL_W-1:0] mul_im_cos = q_im_in * cos_val;

    localparam signed [MUL_W-1:0] ROUND_CONST = (1 <<< 14);

    wire signed [MUL_W-1:0] tr_full = mul_re_cos - mul_im_sin + ROUND_CONST;
    wire signed [MUL_W-1:0] ti_full = mul_re_sin + mul_im_cos + ROUND_CONST;

    wire signed [MUL_W-1:0] tr_shifted = tr_full >>> 15;
    wire signed [MUL_W-1:0] ti_shifted = ti_full >>> 15;

    // Rounded rotated values fit within IN_W bits since |cos|,|sin| <= 32767/32768 < 1.0
    wire signed [IN_W-1:0] tr = tr_shifted[IN_W-1:0];
    wire signed [IN_W-1:0] ti = ti_shifted[IN_W-1:0];

    // Sign-extend operands to OUT_W before add/sub to avoid overflow/wraparound
    wire signed [OUT_W-1:0] p_re_ext = {{(OUT_W-IN_W){p_re_in[IN_W-1]}}, p_re_in};
    wire signed [OUT_W-1:0] p_im_ext = {{(OUT_W-IN_W){p_im_in[IN_W-1]}}, p_im_in};
    wire signed [OUT_W-1:0] tr_ext   = {{(OUT_W-IN_W){tr[IN_W-1]}},      tr};
    wire signed [OUT_W-1:0] ti_ext   = {{(OUT_W-IN_W){ti[IN_W-1]}},      ti};

    assign p_re_out = p_re_ext + tr_ext;
    assign p_im_out = p_im_ext + ti_ext;
    assign q_re_out = p_re_ext - tr_ext;
    assign q_im_out = p_im_ext - ti_ext;

endmodule