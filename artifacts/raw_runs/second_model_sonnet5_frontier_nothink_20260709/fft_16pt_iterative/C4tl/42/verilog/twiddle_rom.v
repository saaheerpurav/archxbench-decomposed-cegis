module twiddle_rom #(
    parameter COEFF_W = 16
) (
    input      [3:0] k,   // 0..15, only 0..7 used given symmetry via caller, but support full range
    output reg signed [COEFF_W-1:0] cos_val,
    output reg signed [COEFF_W-1:0] sin_val
);
    // Q1.15 fixed point cos/sin table for N=16, k=0..15
    always @(*) begin
        case (k)
            4'd0:  begin cos_val =  16'sd32767; sin_val =  16'sd0;     end
            4'd1:  begin cos_val =  16'sd30274; sin_val =  16'sd12540; end
            4'd2:  begin cos_val =  16'sd23170; sin_val =  16'sd23170; end
            4'd3:  begin cos_val =  16'sd12540; sin_val =  16'sd30274; end
            4'd4:  begin cos_val =  16'sd0;     sin_val =  16'sd32767; end
            4'd5:  begin cos_val = -16'sd12540; sin_val =  16'sd30274; end
            4'd6:  begin cos_val = -16'sd23170; sin_val =  16'sd23170; end
            4'd7:  begin cos_val = -16'sd30274; sin_val =  16'sd12540; end
            4'd8:  begin cos_val = -16'sd32768; sin_val =  16'sd0;     end
            4'd9:  begin cos_val = -16'sd30274; sin_val = -16'sd12540; end
            4'd10: begin cos_val = -16'sd23170; sin_val = -16'sd23170; end
            4'd11: begin cos_val = -16'sd12540; sin_val = -16'sd30274; end
            4'd12: begin cos_val =  16'sd0;     sin_val = -16'sd32767; end
            4'd13: begin cos_val =  16'sd12540; sin_val = -16'sd30274; end
            4'd14: begin cos_val =  16'sd23170; sin_val = -16'sd23170; end
            4'd15: begin cos_val =  16'sd30274; sin_val = -16'sd12540; end
            default: begin cos_val = 16'sd0; sin_val = 16'sd0; end
        endcase
    end
endmodule