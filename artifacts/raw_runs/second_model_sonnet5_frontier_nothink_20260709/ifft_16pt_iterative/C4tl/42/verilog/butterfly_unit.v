`timescale 1ns/1ps
// Combinational radix-2 DIT butterfly unit with Q1.15 twiddle multiply
module butterfly_unit #(
    parameter DATA_W  = 16,
    parameter COEFF_W = 16
) (
    input  signed [DATA_W-1:0]   xp_re,
    input  signed [DATA_W-1:0]   xp_im,
    input  signed [DATA_W-1:0]   xq_re,
    input  signed [DATA_W-1:0]   xq_im,
    input  signed [COEFF_W-1:0]  cos_val,
    input  signed [COEFF_W-1:0]  sin_val,
    output signed [DATA_W-1:0]   yp_re,
    output signed [DATA_W-1:0]   yp_im,
    output signed [DATA_W-1:0]   yq_re,
    output signed [DATA_W-1:0]   yq_im
);

    // rounding constant 2^14
    localparam signed [31:0] ROUND_CONST = 32'sd16384;

    // Full-precision products of xq (DATA_W bits) x twiddle (COEFF_W bits)
    wire signed [DATA_W+COEFF_W-1:0] mult_rr, mult_ii, mult_ri, mult_ir;

    assign mult_rr = xq_re * cos_val;
    assign mult_ii = xq_im * sin_val;
    assign mult_ri = xq_re * sin_val;
    assign mult_ir = xq_im * cos_val;

    // Extra headroom bits for the add + rounding constant
    wire signed [DATA_W+COEFF_W+1:0] tr_full, ti_full;
    assign tr_full = {{2{mult_rr[DATA_W+COEFF_W-1]}}, mult_rr} -
                      {{2{mult_ii[DATA_W+COEFF_W-1]}}, mult_ii} + ROUND_CONST;
    assign ti_full = {{2{mult_ri[DATA_W+COEFF_W-1]}}, mult_ri} +
                      {{2{mult_ir[DATA_W+COEFF_W-1]}}, mult_ir} + ROUND_CONST;

    // Q1.15 rounding multiply: arithmetic shift right by 15
    wire signed [DATA_W+COEFF_W+1:0] tr_shift, ti_shift;
    assign tr_shift = tr_full >>> 15;
    assign ti_shift = ti_full >>> 15;

    // Truncate to DATA_W bits (values are expected to fit within DATA_W bits
    // given proper headroom provisioning by the instantiating stage)
    wire signed [DATA_W-1:0] tr, ti;
    assign tr = tr_shift[DATA_W-1:0];
    assign ti = ti_shift[DATA_W-1:0];

    assign yp_re = xp_re + tr;
    assign yp_im = xp_im + ti;
    assign yq_re = xp_re - tr;
    assign yq_im = xp_im - ti;

endmodule