`timescale 1ns/1ps

module fp_highpass_fir #(
    parameter TAP_CNT    = 31,
    parameter PIPE_DEPTH = 2
) (
    input                   clk,
    input                   rst,
    input                   valid_in,
    input   [31:0]          data_in,
    output                  valid_out,
    output  reg [31:0]      data_out
);

    integer i;
    reg [31:0] delay_line [0:TAP_CNT-1];
    reg started;

    assign valid_out = started;

    function [31:0] coeff_at;
        input integer idx;
        begin
            case (idx)
                0:  coeff_at = 32'ha1381601;
                1:  coeff_at = 32'hba9dbdb2;
                2:  coeff_at = 32'hbb36c8a9;
                3:  coeff_at = 32'hbb8ac191;
                4:  coeff_at = 32'hbb816a82;
                5:  coeff_at = 32'h22325551;
                6:  coeff_at = 32'h3c07824b;
                7:  coeff_at = 32'h3c987e0d;
                8:  coeff_at = 32'h3cd058cf;
                9:  coeff_at = 32'h3cae415b;
                10: coeff_at = 32'ha2dd7a7a;
                11: coeff_at = 32'hbd226db2;
                12: coeff_at = 32'hbdbc821d;
                13: coeff_at = 32'hbe14d580;
                14: coeff_at = 32'hbe3da98f;
                15: coeff_at = 32'h3f4ccccd;
                16: coeff_at = 32'hbe3da98f;
                17: coeff_at = 32'hbe14d580;
                18: coeff_at = 32'hbdbc821d;
                19: coeff_at = 32'hbd226db2;
                20: coeff_at = 32'ha2dd7a7a;
                21: coeff_at = 32'h3cae415b;
                22: coeff_at = 32'h3cd058cf;
                23: coeff_at = 32'h3c987e0d;
                24: coeff_at = 32'h3c07824b;
                25: coeff_at = 32'h22325551;
                26: coeff_at = 32'hbb816a82;
                27: coeff_at = 32'hbb8ac191;
                28: coeff_at = 32'hbb36c8a9;
                29: coeff_at = 32'hba9dbdb2;
                30: coeff_at = 32'ha1381601;
                default: coeff_at = 32'h00000000;
            endcase
        end
    endfunction

    function signed [63:0] fp_to_q30;
        input [31:0] fp;
        reg sign;
        reg [7:0] exp;
        reg [23:0] mant;
        integer sh;
        reg signed [63:0] val;
        begin
            sign = fp[31];
            exp  = fp[30:23];

            if (exp == 8'd0) begin
                fp_to_q30 = 64'sd0;
            end else begin
                mant = {1'b1, fp[22:0]};
                sh = exp - 127 - 23 + 30;

                if (sh >= 0)
                    val = $signed({1'b0, mant}) <<< sh;
                else
                    val = $signed({1'b0, mant}) >>> (-sh);

                fp_to_q30 = sign ? -val : val;
            end
        end
    endfunction

    function [31:0] q30_to_fp;
        input signed [63:0] q;
        reg sign;
        reg [63:0] mag;
        reg [63:0] norm;
        reg [7:0] exp_field;
        integer msb;
        integer exp_unbiased;
        begin
            if (q == 64'sd0) begin
                q30_to_fp = 32'h00000000;
            end else begin
                sign = q[63];
                mag = sign ? -q : q;

                msb = 63;
                while (msb > 0 && mag[msb] == 1'b0)
                    msb = msb - 1;

                exp_unbiased = msb - 30;
                exp_field = exp_unbiased + 127;

                if (msb >= 23)
                    norm = mag >> (msb - 23);
                else
                    norm = mag << (23 - msb);

                q30_to_fp = {sign, exp_field, norm[22:0]};
            end
        end
    endfunction

    function [31:0] sample_at_after_shift;
        input integer idx;
        begin
            if (idx == 0)
                sample_at_after_shift = data_in;
            else
                sample_at_after_shift = delay_line[idx-1];
        end
    endfunction

    function [31:0] fir_result;
        integer k;
        reg signed [63:0] sample_q30;
        reg signed [63:0] coeff_q30;
        reg signed [127:0] acc_q60;
        reg signed [63:0] acc_q30;
        begin
            acc_q60 = 128'sd0;

            for (k = 0; k < TAP_CNT; k = k + 1) begin
                sample_q30 = fp_to_q30(sample_at_after_shift(k));
                coeff_q30  = fp_to_q30(coeff_at(k));
                acc_q60 = acc_q60 + (sample_q30 * coeff_q30);
            end

            acc_q30 = acc_q60 >>> 30;
            fir_result = q30_to_fp(acc_q30);
        end
    endfunction

    always @(posedge clk) begin
        if (rst) begin
            for (i = 0; i < TAP_CNT; i = i + 1)
                delay_line[i] <= 32'h00000000;

            started  <= 1'b0;
            data_out <= 32'h00000000;
        end else begin
            if (valid_in) begin
                started  <= 1'b1;
                data_out <= fir_result();

                for (i = TAP_CNT-1; i > 0; i = i - 1)
                    delay_line[i] <= delay_line[i-1];

                delay_line[0] <= data_in;
            end
        end
    end

endmodule