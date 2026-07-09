`timescale 1ns/1ps
// Combinational twiddle factor ROM for N=16 FFT/IFFT
// tw_idx ranges 0..8 (only unique magnitudes needed for N=16, k=0..8)
//
// Table (Q1.15, COEFF_W=16):
//   cos_q15[k] = round(cos(2*pi*k/16) * 32768), clipped to [-32768, 32767]
//   sin_q15[k] = round(sin(2*pi*k/16) * 32768), clipped to [-32768, 32767]
//
// Mode convention:
//   mode=1 (IFFT): butterfly computes (xq.re + j*xq.im) * (cos + j*sin)
//                  -> requires sin_val = +sin_base (as tabulated)
//   mode=0 (FFT):  butterfly needs (xq.re + j*xq.im) * (cos - j*sin)
//                  -> requires sin_val = -sin_base
module twiddle_rom #(
    parameter COEFF_W = 16
) (
    input  [3:0] tw_idx,   // 0..8
    input        mode,     // 0: FFT (negative exponent), 1: IFFT (conjugated / positive exponent)
    output reg signed [COEFF_W-1:0] cos_val,
    output reg signed [COEFF_W-1:0] sin_val
);

    reg signed [COEFF_W-1:0] cos_base;
    reg signed [COEFF_W-1:0] sin_base;

    always @(*) begin
        case (tw_idx)
            4'd0: begin cos_base =  16'sd32767; sin_base =      16'sd0; end
            4'd1: begin cos_base =  16'sd30274; sin_base =  16'sd12540; end
            4'd2: begin cos_base =  16'sd23170; sin_base =  16'sd23170; end
            4'd3: begin cos_base =  16'sd12540; sin_base =  16'sd30274; end
            4'd4: begin cos_base =      16'sd0; sin_base =  16'sd32767; end
            4'd5: begin cos_base = -16'sd12540; sin_base =  16'sd30274; end
            4'd6: begin cos_base = -16'sd23170; sin_base =  16'sd23170; end
            4'd7: begin cos_base = -16'sd30274; sin_base =  16'sd12540; end
            4'd8: begin cos_base = -16'sd32768; sin_base =      16'sd0; end
            default: begin cos_base = 16'sd0; sin_base = 16'sd0; end
        endcase

        cos_val = cos_base;

        // IFFT (mode=1): use table value directly -> positive-exponent (e^{+j*theta}) twiddle
        // FFT  (mode=0): negate sin -> negative-exponent (e^{-j*theta}) twiddle
        if (mode)
            sin_val = sin_base;
        else
            sin_val = -sin_base;
    end

endmodule