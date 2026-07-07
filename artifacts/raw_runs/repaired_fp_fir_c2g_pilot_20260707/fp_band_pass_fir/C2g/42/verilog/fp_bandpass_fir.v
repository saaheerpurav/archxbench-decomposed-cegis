`timescale 1ns/1ps

module fp_bandpass_fir #(
    parameter TAP_CNT    = 63,
    parameter PIPE_DEPTH = 2
) (
    input                   clk,
    input                   rst,
    input                   valid_in,
    input       [31:0]      data_in,
    output                  valid_out,
    output      [31:0]      data_out
);

    localparam USE_TAPS = 31;

    reg signed [31:0] sample_sr [0:USE_TAPS-1];
    integer i;

    assign valid_out = valid_in;

    function signed [31:0] fp32_to_q24;
        input [31:0] f;
        reg sign;
        reg [7:0] exp;
        reg [23:0] mant;
        reg signed [63:0] val;
        integer shift;
        begin
            sign = f[31];
            exp  = f[30:23];

            if (exp == 8'd0) begin
                fp32_to_q24 = 32'sd0;
            end else if (exp == 8'hff) begin
                fp32_to_q24 = sign ? -32'sh7fffffff : 32'sh7fffffff;
            end else begin
                mant = {1'b1, f[22:0]};
                shift = exp - 127 - 23 + 24;

                if (shift >= 0)
                    val = $signed({1'b0, mant}) <<< shift;
                else
                    val = $signed({1'b0, mant}) >>> (-shift);

                if (sign)
                    val = -val;

                if (val > 64'sd2147483647)
                    fp32_to_q24 = 32'sh7fffffff;
                else if (val < -64'sd2147483648)
                    fp32_to_q24 = -32'sh80000000;
                else
                    fp32_to_q24 = val[31:0];
            end
        end
    endfunction

    function [31:0] q24_to_fp32;
        input signed [63:0] q;
        reg sign;
        reg [63:0] abs_q;
        reg [63:0] norm;
        reg [7:0] exp;
        reg [22:0] frac;
        integer msb;
        integer k;
        begin
            if (q == 0) begin
                q24_to_fp32 = 32'h00000000;
            end else begin
                sign = q[63];
                abs_q = sign ? -q : q;

                msb = 0;
                for (k = 0; k < 64; k = k + 1)
                    if (abs_q[k])
                        msb = k;

                exp = 127 + msb - 24;

                if (msb >= 23)
                    norm = abs_q >> (msb - 23);
                else
                    norm = abs_q << (23 - msb);

                frac = norm[22:0];
                q24_to_fp32 = {sign, exp, frac};
            end
        end
    endfunction

    function signed [31:0] coeff_q30;
        input integer idx;
        begin
            case (idx)
                0:  coeff_q30 =  32'sd2890502;
                1:  coeff_q30 =  32'sd4025467;
                2:  coeff_q30 =  32'sd6133880;
                3:  coeff_q30 =  32'sd9162920;
                4:  coeff_q30 =  32'sd12540228;
                5:  coeff_q30 =  32'sd15174020;
                6:  coeff_q30 =  32'sd15636835;
                7:  coeff_q30 =  32'sd12503723;
                8:  coeff_q30 =  32'sd4745932;
                9:  coeff_q30 = -32'sd7898242;
                10: coeff_q30 = -32'sd24701471;
                11: coeff_q30 = -32'sd43924691;
                12: coeff_q30 = -32'sd63160750;
                13: coeff_q30 = -32'sd79558966;
                14: coeff_q30 = -32'sd90623810;
                15: coeff_q30 = -32'sd94489281;
                16: coeff_q30 = -32'sd90623810;
                17: coeff_q30 = -32'sd79558966;
                18: coeff_q30 = -32'sd63160750;
                19: coeff_q30 = -32'sd43924691;
                20: coeff_q30 = -32'sd24701471;
                21: coeff_q30 = -32'sd7898242;
                22: coeff_q30 =  32'sd4745932;
                23: coeff_q30 =  32'sd12503723;
                24: coeff_q30 =  32'sd15636835;
                25: coeff_q30 =  32'sd15174020;
                26: coeff_q30 =  32'sd12540228;
                27: coeff_q30 =  32'sd9162920;
                28: coeff_q30 =  32'sd6133880;
                29: coeff_q30 =  32'sd4025467;
                30: coeff_q30 =  32'sd2890502;
                default: coeff_q30 = 32'sd0;
            endcase
        end
    endfunction

    reg signed [31:0] current_sample;
    reg signed [95:0] acc;
    reg signed [63:0] y_q24;

    always @(*) begin
        current_sample = valid_in ? fp32_to_q24(data_in) : 32'sd0;
        acc = 96'sd0;

        acc = acc + ($signed(current_sample) * $signed(coeff_q30(0)));

        for (i = 1; i < USE_TAPS; i = i + 1)
            acc = acc + ($signed(sample_sr[i-1]) * $signed(coeff_q30(i)));

        y_q24 = acc >>> 30;
    end

    assign data_out = q24_to_fp32(y_q24);

    always @(posedge clk) begin
        if (rst) begin
            for (i = 0; i < USE_TAPS; i = i + 1)
                sample_sr[i] <= 32'sd0;
        end else begin
            sample_sr[0] <= valid_in ? fp32_to_q24(data_in) : 32'sd0;

            for (i = 1; i < USE_TAPS; i = i + 1)
                sample_sr[i] <= sample_sr[i-1];
        end
    end

endmodule