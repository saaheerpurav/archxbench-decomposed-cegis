// Complex radix-2 DIT butterfly with Q1.15 twiddle multiply (rounded).
//   tr = (xq.re*cos - xq.im*sin + 2^14) >>> 15
//   ti = (xq.re*sin + xq.im*cos + 2^14) >>> 15
//   yp = xp + (tr + j*ti)
//   yq = xp - (tr + j*ti)
module butterfly_unit #(
    parameter DATA_W  = 16,
    parameter COEFF_W = 16
) (
    input  signed [DATA_W-1:0]  xp_re,
    input  signed [DATA_W-1:0]  xp_im,
    input  signed [DATA_W-1:0]  xq_re,
    input  signed [DATA_W-1:0]  xq_im,
    input  signed [COEFF_W-1:0] cos_val,
    input  signed [COEFF_W-1:0] sin_val,
    output signed [DATA_W-1:0]  yp_re,
    output signed [DATA_W-1:0]  yp_im,
    output signed [DATA_W-1:0]  yq_re,
    output signed [DATA_W-1:0]  yq_im
);
    localparam PROD_W = DATA_W + COEFF_W + 2;

    wire signed [PROD_W-1:0] mult_re_cos, mult_im_sin, mult_re_sin, mult_im_cos;
    wire signed [PROD_W-1:0] sum_tr, sum_ti;
    wire signed [PROD_W-1:0] rounded_tr, rounded_ti;
    wire signed [PROD_W-1:0] tr_full, ti_full;
    wire signed [DATA_W-1:0] tr, ti;

    assign mult_re_cos = xq_re * cos_val;
    assign mult_im_sin = xq_im * sin_val;
    assign mult_re_sin = xq_re * sin_val;
    assign mult_im_cos = xq_im * cos_val;

    assign sum_tr = mult_re_cos - mult_im_sin;
    assign sum_ti = mult_re_sin + mult_im_cos;

    assign rounded_tr = sum_tr + (1 << 14);
    assign rounded_ti = sum_ti + (1 << 14);

    // Arithmetic right shift by 15 (Q1.15 de-scale), then take low DATA_W bits
    assign tr_full = rounded_tr >>> 15;
    assign ti_full = rounded_ti >>> 15;

    assign tr = tr_full[DATA_W-1:0];
    assign ti = ti_full[DATA_W-1:0];

    assign yp_re = xp_re + tr;
    assign yp_im = xp_im + ti;
    assign yq_re = xp_re - tr;
    assign yq_im = xp_im - ti;

endmodule