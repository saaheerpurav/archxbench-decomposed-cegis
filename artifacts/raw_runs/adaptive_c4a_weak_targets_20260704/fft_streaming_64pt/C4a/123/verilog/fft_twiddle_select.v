`timescale 1ns/1ps

module fft_twiddle_select #(
    parameter OUT_W = 20,
    parameter STAGE_ID = 0
) (
    input  [5:0] sample_index,
    output reg signed [OUT_W-1:0] tw_real,
    output reg signed [OUT_W-1:0] tw_imag
);
    localparam integer FFT_N = 64;
    localparam integer LOG_N = 6;

    function signed [OUT_W-1:0] scale_q15;
        input signed [15:0] v;
        reg signed [47:0] prod;
        reg signed [47:0] max_pos;
        begin
            max_pos = (48'sd1 << (OUT_W-1)) - 48'sd1;
            prod = $signed(v) * max_pos;
            scale_q15 = prod / 48'sd32767;
        end
    endfunction

    function [5:0] twiddle_index;
        input [5:0] idx;
        reg [5:0] local_pos;
        begin
            if (STAGE_ID <= 0) begin
                twiddle_index = 6'd0;
            end else if (STAGE_ID >= LOG_N) begin
                twiddle_index = idx[5:0];
            end else begin
                local_pos = idx & ((6'd1 << STAGE_ID) - 6'd1);
                twiddle_index = local_pos << ((LOG_N - 1) - STAGE_ID);
            end
        end
    endfunction

    always @* begin
        case (twiddle_index(sample_index))
            6'd0:  begin tw_real = scale_q15( 16'sd32767); tw_imag = scale_q15(      16'sd0); end
            6'd1:  begin tw_real = scale_q15( 16'sd32610); tw_imag = scale_q15( -16'sd3212); end
            6'd2:  begin tw_real = scale_q15( 16'sd32138); tw_imag = scale_q15( -16'sd6393); end
            6'd3:  begin tw_real = scale_q15( 16'sd31357); tw_imag = scale_q15( -16'sd9512); end
            6'd4:  begin tw_real = scale_q15( 16'sd30274); tw_imag = scale_q15(-16'sd12540); end
            6'd5:  begin tw_real = scale_q15( 16'sd28899); tw_imag = scale_q15(-16'sd15447); end
            6'd6:  begin tw_real = scale_q15( 16'sd27245); tw_imag = scale_q15(-16'sd18205); end
            6'd7:  begin tw_real = scale_q15( 16'sd25330); tw_imag = scale_q15(-16'sd20787); end
            6'd8:  begin tw_real = scale_q15( 16'sd23170); tw_imag = scale_q15(-16'sd23170); end
            6'd9:  begin tw_real = scale_q15( 16'sd20787); tw_imag = scale_q15(-16'sd25330); end
            6'd10: begin tw_real = scale_q15( 16'sd18205); tw_imag = scale_q15(-16'sd27245); end
            6'd11: begin tw_real = scale_q15( 16'sd15447); tw_imag = scale_q15(-16'sd28899); end
            6'd12: begin tw_real = scale_q15( 16'sd12540); tw_imag = scale_q15(-16'sd30274); end
            6'd13: begin tw_real = scale_q15(  16'sd9512); tw_imag = scale_q15(-16'sd31357); end
            6'd14: begin tw_real = scale_q15(  16'sd6393); tw_imag = scale_q15(-16'sd32138); end
            6'd15: begin tw_real = scale_q15(  16'sd3212); tw_imag = scale_q15(-16'sd32610); end
            6'd16: begin tw_real = scale_q15(      16'sd0); tw_imag = scale_q15(-16'sd32767); end
            6'd17: begin tw_real = scale_q15( -16'sd3212); tw_imag = scale_q15(-16'sd32610); end
            6'd18: begin tw_real = scale_q15( -16'sd6393); tw_imag = scale_q15(-16'sd32138); end
            6'd19: begin tw_real = scale_q15( -16'sd9512); tw_imag = scale_q15(-16'sd31357); end
            6'd20: begin tw_real = scale_q15(-16'sd12540); tw_imag = scale_q15(-16'sd30274); end
            6'd21: begin tw_real = scale_q15(-16'sd15447); tw_imag = scale_q15(-16'sd28899); end
            6'd22: begin tw_real = scale_q15(-16'sd18205); tw_imag = scale_q15(-16'sd27245); end
            6'd23: begin tw_real = scale_q15(-16'sd20787); tw_imag = scale_q15(-16'sd25330); end
            6'd24: begin tw_real = scale_q15(-16'sd23170); tw_imag = scale_q15(-16'sd23170); end
            6'd25: begin tw_real = scale_q15(-16'sd25330); tw_imag = scale_q15(-16'sd20787); end
            6'd26: begin tw_real = scale_q15(-16'sd27245); tw_imag = scale_q15(-16'sd18205); end
            6'd27: begin tw_real = scale_q15(-16'sd28899); tw_imag = scale_q15(-16'sd15447); end
            6'd28: begin tw_real = scale_q15(-16'sd30274); tw_imag = scale_q15(-16'sd12540); end
            6'd29: begin tw_real = scale_q15(-16'sd31357); tw_imag = scale_q15( -16'sd9512); end
            6'd30: begin tw_real = scale_q15(-16'sd32138); tw_imag = scale_q15( -16'sd6393); end
            6'd31: begin tw_real = scale_q15(-16'sd32610); tw_imag = scale_q15( -16'sd3212); end
            default: begin tw_real = scale_q15(16'sd32767); tw_imag = scale_q15(16'sd0); end
        endcase
    end
endmodule