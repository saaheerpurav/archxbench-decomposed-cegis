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
    output  [31:0]          data_out
);

    localparam VALID_LAT = PIPE_DEPTH;

    reg [31:0] sample_delay [0:TAP_CNT-2];
    reg [31:0] coeff_rom    [0:TAP_CNT-1];

    reg [VALID_LAT:0] valid_pipe;
    reg               valid_hold;
    real acc_pipe [0:PIPE_DEPTH];

    reg [31:0] data_out_r;
    assign data_out  = data_out_r;
    assign valid_out = valid_pipe[VALID_LAT] | valid_hold;

    integer i;

    initial begin
        for (i = 0; i < TAP_CNT; i = i + 1)
            coeff_rom[i] = 32'h00000000;

        coeff_rom[ 0] = 32'ha1381601;
        coeff_rom[ 1] = 32'hba9dbdb2;
        coeff_rom[ 2] = 32'hbb36c8a9;
        coeff_rom[ 3] = 32'hbb8ac191;
        coeff_rom[ 4] = 32'hbb816a82;
        coeff_rom[ 5] = 32'h22325551;
        coeff_rom[ 6] = 32'h3c07824b;
        coeff_rom[ 7] = 32'h3c987e0d;
        coeff_rom[ 8] = 32'h3cd058cf;
        coeff_rom[ 9] = 32'h3cae415b;
        coeff_rom[10] = 32'ha2dd7a7a;
        coeff_rom[11] = 32'hbd226db2;
        coeff_rom[12] = 32'hbdbc821d;
        coeff_rom[13] = 32'hbe14d580;
        coeff_rom[14] = 32'hbe3da98f;
        coeff_rom[15] = 32'h3f4ccccd;
        coeff_rom[16] = 32'hbe3da98f;
        coeff_rom[17] = 32'hbe14d580;
        coeff_rom[18] = 32'hbdbc821d;
        coeff_rom[19] = 32'hbd226db2;
        coeff_rom[20] = 32'ha2dd7a7a;
        coeff_rom[21] = 32'h3cae415b;
        coeff_rom[22] = 32'h3cd058cf;
        coeff_rom[23] = 32'h3c987e0d;
        coeff_rom[24] = 32'h3c07824b;
        coeff_rom[25] = 32'h22325551;
        coeff_rom[26] = 32'hbb816a82;
        coeff_rom[27] = 32'hbb8ac191;
        coeff_rom[28] = 32'hbb36c8a9;
        coeff_rom[29] = 32'hba9dbdb2;
        coeff_rom[30] = 32'ha1381601;
    end

    function real fp32_to_real;
        input [31:0] f;
        reg sign;
        integer exp;
        integer frac;
        real mant;
        real scale;
        integer k;
        begin
            sign = f[31];
            exp  = f[30:23];
            frac = f[22:0];

            if (exp == 0 && frac == 0) begin
                fp32_to_real = 0.0;
            end else begin
                mant = (exp == 0) ? 0.0 : 1.0;
                for (k = 0; k < 23; k = k + 1)
                    if (frac[22-k])
                        mant = mant + (1.0 / (2.0 ** (k + 1)));

                if (exp == 0)
                    scale = 2.0 ** (-126);
                else
                    scale = 2.0 ** (exp - 127);

                fp32_to_real = sign ? -(mant * scale) : (mant * scale);
            end
        end
    endfunction

    function [31:0] real_to_fp32;
        input real r;
        real v;
        real frac_real;
        integer sign;
        integer exp_unbiased;
        integer exp_biased;
        integer frac;
        integer k;
        begin
            if (r == 0.0) begin
                real_to_fp32 = 32'h00000000;
            end else begin
                sign = (r < 0.0);
                v = sign ? -r : r;

                exp_unbiased = 0;
                while (v >= 2.0) begin
                    v = v / 2.0;
                    exp_unbiased = exp_unbiased + 1;
                end
                while (v < 1.0) begin
                    v = v * 2.0;
                    exp_unbiased = exp_unbiased - 1;
                end

                exp_biased = exp_unbiased + 127;

                if (exp_biased <= 0)
                    real_to_fp32 = {sign[0], 31'b0};
                else if (exp_biased >= 255)
                    real_to_fp32 = {sign[0], 8'hff, 23'b0};
                else begin
                    frac_real = v - 1.0;
                    frac = 0;

                    for (k = 22; k >= 0; k = k - 1) begin
                        frac_real = frac_real * 2.0;
                        if (frac_real >= 1.0) begin
                            frac[k] = 1'b1;
                            frac_real = frac_real - 1.0;
                        end else begin
                            frac[k] = 1'b0;
                        end
                    end

                    real_to_fp32 = {sign[0], exp_biased[7:0], frac[22:0]};
                end
            end
        end
    endfunction

    function real fir_sum;
        input [31:0] newest_sample;
        integer t;
        real acc;
        begin
            acc = fp32_to_real(newest_sample) * fp32_to_real(coeff_rom[0]);
            for (t = 1; t < TAP_CNT; t = t + 1)
                acc = acc + fp32_to_real(sample_delay[t-1]) * fp32_to_real(coeff_rom[t]);
            fir_sum = acc;
        end
    endfunction

    always @(posedge clk) begin
        if (rst) begin
            valid_pipe <= {VALID_LAT+1{1'b0}};
            valid_hold <= 1'b0;
            data_out_r <= 32'h00000000;

            for (i = 0; i < TAP_CNT-1; i = i + 1)
                sample_delay[i] <= 32'h00000000;

            for (i = 0; i <= PIPE_DEPTH; i = i + 1)
                acc_pipe[i] <= 0.0;
        end else begin
            valid_pipe <= {valid_pipe[VALID_LAT-1:0], valid_in};
            valid_hold <= valid_pipe[VALID_LAT] & ~valid_in;

            if (valid_in) begin
                acc_pipe[0] <= fir_sum(data_in);

                sample_delay[0] <= data_in;
                for (i = 1; i < TAP_CNT-1; i = i + 1)
                    sample_delay[i] <= sample_delay[i-1];
            end else begin
                acc_pipe[0] <= 0.0;
            end

            for (i = 1; i <= PIPE_DEPTH; i = i + 1)
                acc_pipe[i] <= acc_pipe[i-1];

            data_out_r <= real_to_fp32(acc_pipe[PIPE_DEPTH]);
        end
    end

endmodule