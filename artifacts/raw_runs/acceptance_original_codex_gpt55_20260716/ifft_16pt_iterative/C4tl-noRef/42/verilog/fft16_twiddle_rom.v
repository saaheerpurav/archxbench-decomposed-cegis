`timescale 1ns/1ps

module fft16_twiddle_rom #(
    parameter COEFF_W = 16
) (
    input  wire [3:0] tw_idx,
    output reg signed [COEFF_W-1:0] tw_real,
    output reg signed [COEFF_W-1:0] tw_imag
);

    always @* begin
        case (tw_idx)
            4'd0: begin
                tw_real = 16'sd32767;
                tw_imag = 16'sd0;
            end
            4'd1: begin
                tw_real = 16'sd30274;
                tw_imag = 16'sd12540;
            end
            4'd2: begin
                tw_real = 16'sd23170;
                tw_imag = 16'sd23170;
            end
            4'd3: begin
                tw_real = 16'sd12540;
                tw_imag = 16'sd30274;
            end
            4'd4: begin
                tw_real = 16'sd0;
                tw_imag = 16'sd32767;
            end
            4'd5: begin
                tw_real = -16'sd12540;
                tw_imag = 16'sd30274;
            end
            4'd6: begin
                tw_real = -16'sd23170;
                tw_imag = 16'sd23170;
            end
            4'd7: begin
                tw_real = -16'sd30274;
                tw_imag = 16'sd12540;
            end
            4'd8: begin
                tw_real = -16'sd32768;
                tw_imag = 16'sd0;
            end
            4'd9: begin
                tw_real = -16'sd30274;
                tw_imag = -16'sd12540;
            end
            4'd10: begin
                tw_real = -16'sd23170;
                tw_imag = -16'sd23170;
            end
            4'd11: begin
                tw_real = -16'sd12540;
                tw_imag = -16'sd30274;
            end
            4'd12: begin
                tw_real = 16'sd0;
                tw_imag = -16'sd32768;
            end
            4'd13: begin
                tw_real = 16'sd12540;
                tw_imag = -16'sd30274;
            end
            4'd14: begin
                tw_real = 16'sd23170;
                tw_imag = -16'sd23170;
            end
            4'd15: begin
                tw_real = 16'sd30274;
                tw_imag = -16'sd12540;
            end
            default: begin
                tw_real = 16'sd32767;
                tw_imag = 16'sd0;
            end
        endcase
    end

endmodule