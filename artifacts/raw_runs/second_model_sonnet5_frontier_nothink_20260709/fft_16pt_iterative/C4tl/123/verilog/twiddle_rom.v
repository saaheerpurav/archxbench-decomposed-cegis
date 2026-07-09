module twiddle_rom #(
    parameter COEFF_W = 16
) (
    input  [3:0] index,   // 0..15
    input        mode,    // 0: FFT, 1: IFFT (conjugate)
    output signed [COEFF_W-1:0] cos_val,
    output signed [COEFF_W-1:0] sin_val
);

    reg signed [COEFF_W-1:0] base_cos;
    reg signed [COEFF_W-1:0] base_sin;

    always @(*) begin
        case (index)
            4'd0:  begin base_cos =  16'sd32767; base_sin =  16'sd0;     end
            4'd1:  begin base_cos =  16'sd30274; base_sin =  16'sd12540; end
            4'd2:  begin base_cos =  16'sd23170; base_sin =  16'sd23170; end
            4'd3:  begin base_cos =  16'sd12540; base_sin =  16'sd30274; end
            4'd4:  begin base_cos =  16'sd0;     base_sin =  16'sd32767; end
            4'd5:  begin base_cos = -16'sd12540; base_sin =  16'sd30274; end
            4'd6:  begin base_cos = -16'sd23170; base_sin =  16'sd23170; end
            4'd7:  begin base_cos = -16'sd30274; base_sin =  16'sd12540; end
            4'd8:  begin base_cos = -16'sd32768; base_sin =  16'sd0;     end
            4'd9:  begin base_cos = -16'sd30274; base_sin = -16'sd12540; end
            4'd10: begin base_cos = -16'sd23170; base_sin = -16'sd23170; end
            4'd11: begin base_cos = -16'sd12540; base_sin = -16'sd30274; end
            4'd12: begin base_cos =  16'sd0;     base_sin = -16'sd32767; end
            4'd13: begin base_cos =  16'sd12540; base_sin = -16'sd30274; end
            4'd14: begin base_cos =  16'sd23170; base_sin = -16'sd23170; end
            4'd15: begin base_cos =  16'sd30274; base_sin = -16'sd12540; end
            default: begin base_cos = 16'sd0; base_sin = 16'sd0; end
        endcase
    end

    // FFT mode: W = cos - j*sin  -> sin_val used as-is (subtracted in butterfly)
    // IFFT mode: W = cos + j*sin -> negate sin so butterfly (which subtracts) effectively adds
    assign cos_val = base_cos;
    assign sin_val = mode ? (-base_sin) : base_sin;

endmodule