module fft16_twiddle_rom #(
    parameter COEFF_W = 16
) (
    input  wire [3:0] tw_idx,
    input  wire       mode,       // 0: FFT => cos - j*sin, 1: IFFT => cos + j*sin
    output reg signed [COEFF_W-1:0] tw_real,
    output reg signed [COEFF_W-1:0] tw_imag
);

    reg signed [COEFF_W-1:0] sin_q15;

    always @* begin
        tw_real = {COEFF_W{1'b0}};
        sin_q15 = {COEFF_W{1'b0}};

        case (tw_idx)
            4'd0: begin
                tw_real = 16'sh7FFF; //  32767
                sin_q15 = 16'sh0000; //      0
            end
            4'd1: begin
                tw_real = 16'sh7642; //  30274
                sin_q15 = 16'sh30FC; //  12540
            end
            4'd2: begin
                tw_real = 16'sh5A82; //  23170
                sin_q15 = 16'sh5A82; //  23170
            end
            4'd3: begin
                tw_real = 16'sh30FC; //  12540
                sin_q15 = 16'sh7642; //  30274
            end
            4'd4: begin
                tw_real = 16'sh0000; //      0
                sin_q15 = 16'sh7FFF; //  32767
            end
            4'd5: begin
                tw_real = 16'shCF04; // -12540
                sin_q15 = 16'sh7642; //  30274
            end
            4'd6: begin
                tw_real = 16'shA57E; // -23170
                sin_q15 = 16'sh5A82; //  23170
            end
            4'd7: begin
                tw_real = 16'sh89BE; // -30274
                sin_q15 = 16'sh30FC; //  12540
            end
            4'd8: begin
                tw_real = 16'sh8000; // -32768
                sin_q15 = 16'sh0000; //      0
            end
            4'd9: begin
                tw_real = 16'sh89BE; // -30274
                sin_q15 = 16'shCF04; // -12540
            end
            4'd10: begin
                tw_real = 16'shA57E; // -23170
                sin_q15 = 16'shA57E; // -23170
            end
            4'd11: begin
                tw_real = 16'shCF04; // -12540
                sin_q15 = 16'sh89BE; // -30274
            end
            4'd12: begin
                tw_real = 16'sh0000; //      0
                sin_q15 = 16'sh8000; // -32768
            end
            4'd13: begin
                tw_real = 16'sh30FC; //  12540
                sin_q15 = 16'sh89BE; // -30274
            end
            4'd14: begin
                tw_real = 16'sh5A82; //  23170
                sin_q15 = 16'shA57E; // -23170
            end
            4'd15: begin
                tw_real = 16'sh7642; //  30274
                sin_q15 = 16'shCF04; // -12540
            end
            default: begin
                tw_real = 16'sh7FFF;
                sin_q15 = 16'sh0000;
            end
        endcase

        tw_imag = mode ? sin_q15 : -sin_q15;
    end

endmodule