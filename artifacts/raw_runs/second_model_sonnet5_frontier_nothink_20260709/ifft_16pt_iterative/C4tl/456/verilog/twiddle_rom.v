// Twiddle factor ROM, Q1.15 fixed point, indices 0..8 (k=0..N/2)
// Combinational lookup as specified in the twiddle table.
// idx range used by stage_index_gen for N=16 is 0..8 inclusive.
module twiddle_rom #(
    parameter COEFF_W = 16
) (
    input  [3:0] idx,
    output reg signed [COEFF_W-1:0] cos_val,
    output reg signed [COEFF_W-1:0] sin_val
);
    always @(*) begin
        case (idx)
            4'd0: begin cos_val = 16'sd32767;  sin_val = 16'sd0;     end
            4'd1: begin cos_val = 16'sd30274;  sin_val = 16'sd12540; end
            4'd2: begin cos_val = 16'sd23170;  sin_val = 16'sd23170; end
            4'd3: begin cos_val = 16'sd12540;  sin_val = 16'sd30274; end
            4'd4: begin cos_val = 16'sd0;      sin_val = 16'sd32767; end
            4'd5: begin cos_val = -16'sd12540; sin_val = 16'sd30274; end
            4'd6: begin cos_val = -16'sd23170; sin_val = 16'sd23170; end
            4'd7: begin cos_val = -16'sd30274; sin_val = 16'sd12540; end
            4'd8: begin cos_val = -16'sd32768; sin_val = 16'sd0;     end
            default: begin cos_val = 16'sd32767; sin_val = 16'sd0;  end
        endcase
    end
endmodule