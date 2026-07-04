`timescale 1ns/1ps

module fft16_twiddle_rom #(
    parameter COEFF_W = 16
) (
    input  [3:0] index,
    output reg signed [COEFF_W-1:0] cos_q15,
    output reg signed [COEFF_W-1:0] sin_q15
);

    always @* begin
        case (index)
            4'd0:  begin cos_q15 =  32767; sin_q15 =      0; end
            4'd1:  begin cos_q15 =  30274; sin_q15 =  12540; end
            4'd2:  begin cos_q15 =  23170; sin_q15 =  23170; end
            4'd3:  begin cos_q15 =  12540; sin_q15 =  30274; end
            4'd4:  begin cos_q15 =      0; sin_q15 =  32767; end
            4'd5:  begin cos_q15 = -12540; sin_q15 =  30274; end
            4'd6:  begin cos_q15 = -23170; sin_q15 =  23170; end
            4'd7:  begin cos_q15 = -30274; sin_q15 =  12540; end
            4'd8:  begin cos_q15 = -32768; sin_q15 =      0; end
            4'd9:  begin cos_q15 = -30274; sin_q15 = -12540; end
            4'd10: begin cos_q15 = -23170; sin_q15 = -23170; end
            4'd11: begin cos_q15 = -12540; sin_q15 = -30274; end
            4'd12: begin cos_q15 =      0; sin_q15 = -32768; end
            4'd13: begin cos_q15 =  12540; sin_q15 = -30274; end
            4'd14: begin cos_q15 =  23170; sin_q15 = -23170; end
            4'd15: begin cos_q15 =  30274; sin_q15 = -12540; end
            default: begin cos_q15 = 32767; sin_q15 = 0; end
        endcase
    end

endmodule