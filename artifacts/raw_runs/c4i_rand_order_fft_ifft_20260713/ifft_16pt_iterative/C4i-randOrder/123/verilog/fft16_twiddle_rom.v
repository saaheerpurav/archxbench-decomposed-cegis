`timescale 1ns/1ps

module fft16_twiddle_rom #(
    parameter N = 16,
    parameter COEFF_W = 16,
    parameter ADDR_W = 4
) (
    input  [ADDR_W-1:0] tw_idx,
    input  mode, // 0: FFT, 1: IFFT
    output reg signed [COEFF_W-1:0] tw_cos,
    output reg signed [COEFF_W-1:0] tw_sin
);

    reg signed [COEFF_W-1:0] sin_pos;

    always @* begin
        case (tw_idx)
            4'd0: begin tw_cos = 16'sd32767;  sin_pos = 16'sd0;     end
            4'd1: begin tw_cos = 16'sd30274;  sin_pos = 16'sd12540; end
            4'd2: begin tw_cos = 16'sd23170;  sin_pos = 16'sd23170; end
            4'd3: begin tw_cos = 16'sd12540;  sin_pos = 16'sd30274; end
            4'd4: begin tw_cos = 16'sd0;      sin_pos = 16'sd32767; end
            4'd5: begin tw_cos = -16'sd12540; sin_pos = 16'sd30274; end
            4'd6: begin tw_cos = -16'sd23170; sin_pos = 16'sd23170; end
            4'd7: begin tw_cos = -16'sd30274; sin_pos = 16'sd12540; end
            4'd8: begin tw_cos = -16'sd32768; sin_pos = 16'sd0;     end
            default: begin tw_cos = 16'sd32767; sin_pos = 16'sd0;   end
        endcase

        if (mode)
            tw_sin = sin_pos;
        else
            tw_sin = -sin_pos;
    end

endmodule