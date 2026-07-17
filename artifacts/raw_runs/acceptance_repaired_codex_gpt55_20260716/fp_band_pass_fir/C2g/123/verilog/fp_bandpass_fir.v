`timescale 1ns/1ps

module fp_bandpass_fir #(
    parameter TAP_CNT = 101
) (
    input wire clk,
    input wire rst,
    input wire valid_in,
    input wire [31:0] data_in,
    output wire valid_out,
    output wire [31:0] data_out
);

    reg valid_out_r;
    reg [31:0] data_out_r;
    reg [31:0] delay [0:TAP_CNT-2];
    reg [31:0] coeff [0:TAP_CNT-1];

    integer i;

    assign valid_out = valid_out_r;
    assign data_out = data_out_r;

    initial begin
        coeff[  0] = 32'h39fd56aa; coeff[  1] = 32'h39a77386;
        coeff[  2] = 32'h39334aac; coeff[  3] = 32'h386d8991;
        coeff[  4] = 32'hb5a5aba3; coeff[  5] = 32'h37bd8450;
        coeff[  6] = 32'h391fc780; coeff[  7] = 32'h39d475a3;
        coeff[  8] = 32'h3a4d6269; coeff[  9] = 32'h3aa61be3;
        coeff[ 10] = 32'h3aed3bf0; coeff[ 11] = 32'h3b192db6;
        coeff[ 12] = 32'h3b347633; coeff[ 13] = 32'h3b418ca6;
        coeff[ 14] = 32'h3b3a03d9; coeff[ 15] = 32'h3b193e82;
        coeff[ 16] = 32'h3abb6ece; coeff[ 17] = 32'h391fa206;
        coeff[ 18] = 32'hbab5ebf4; coeff[ 19] = 32'hbb45facc;
        coeff[ 20] = 32'hbb9488a1; coeff[ 21] = 32'hbbbaa786;
        coeff[ 22] = 32'hbbceb76a; coeff[ 23] = 32'hbbcc46b2;
        coeff[ 24] = 32'hbbb25119; coeff[ 25] = 32'hbb841b84;
        coeff[ 26] = 32'hbb12f16e; coeff[ 27] = 32'hb9e522de;
        coeff[ 28] = 32'h3a74a930; coeff[ 29] = 32'h3ab63a39;
        coeff[ 30] = 32'h3a034101; coeff[ 31] = 32'hbb0600e4;
        coeff[ 32] = 32'hbbd0625a; coeff[ 33] = 32'hbc49a519;
        coeff[ 34] = 32'hbc9f93b5; coeff[ 35] = 32'hbcdeddd2;
        coeff[ 36] = 32'hbd0dbce0; coeff[ 37] = 32'hbd2696ef;
        coeff[ 38] = 32'hbd35d6f1; coeff[ 39] = 32'hbd37d430;
        coeff[ 40] = 32'hbd29e7d2; coeff[ 41] = 32'hbd0adcc4;
        coeff[ 42] = 32'hbcb67535; coeff[ 43] = 32'hbbeaf5be;
        coeff[ 44] = 32'h3c2a8ac6; coeff[ 45] = 32'h3ceeaa3c;
        coeff[ 46] = 32'h3d42697f; coeff[ 47] = 32'h3d82ae39;
        coeff[ 48] = 32'h3d9d14a6; coeff[ 49] = 32'h3dadfa04;
        coeff[ 50] = 32'h3db3ca74; coeff[ 51] = 32'h3dadfa04;
        coeff[ 52] = 32'h3d9d14a6; coeff[ 53] = 32'h3d82ae39;
        coeff[ 54] = 32'h3d42697f; coeff[ 55] = 32'h3ceeaa3c;
        coeff[ 56] = 32'h3c2a8ac6; coeff[ 57] = 32'hbbeaf5be;
        coeff[ 58] = 32'hbcb67535; coeff[ 59] = 32'hbd0adcc4;
        coeff[ 60] = 32'hbd29e7d2; coeff[ 61] = 32'hbd37d430;
        coeff[ 62] = 32'hbd35d6f1; coeff[ 63] = 32'hbd2696ef;
        coeff[ 64] = 32'hbd0dbce0; coeff[ 65] = 32'hbcdeddd2;
        coeff[ 66] = 32'hbc9f93b5; coeff[ 67] = 32'hbc49a519;
        coeff[ 68] = 32'hbbd0625a; coeff[ 69] = 32'hbb0600e4;
        coeff[ 70] = 32'h3a034101; coeff[ 71] = 32'h3ab63a39;
        coeff[ 72] = 32'h3a74a930; coeff[ 73] = 32'hb9e522de;
        coeff[ 74] = 32'hbb12f16e; coeff[ 75] = 32'hbb841b84;
        coeff[ 76] = 32'hbbb25119; coeff[ 77] = 32'hbbcc46b2;
        coeff[ 78] = 32'hbbceb76a; coeff[ 79] = 32'hbbbaa786;
        coeff[ 80] = 32'hbb9488a1; coeff[ 81] = 32'hbb45facc;
        coeff[ 82] = 32'hbab5ebf4; coeff[ 83] = 32'h391fa206;
        coeff[ 84] = 32'h3abb6ece; coeff[ 85] = 32'h3b193e82;
        coeff[ 86] = 32'h3b3a03d9; coeff[ 87] = 32'h3b418ca6;
        coeff[ 88] = 32'h3b347633; coeff[ 89] = 32'h3b192db6;
        coeff[ 90] = 32'h3aed3bf0; coeff[ 91] = 32'h3aa61be3;
        coeff[ 92] = 32'h3a4d6269; coeff[ 93] = 32'h39d475a3;
        coeff[ 94] = 32'h391fc780; coeff[ 95] = 32'h37bd8450;
        coeff[ 96] = 32'hb5a5aba3; coeff[ 97] = 32'h386d8991;
        coeff[ 98] = 32'h39334aac; coeff[ 99] = 32'h39a77386;
        coeff[100] = 32'h39fd56aa;
    end

    function real fp32_to_real;
        input [31:0] bits;
        reg sign;
        integer exp;
        integer frac;
        real mag;
        begin
            sign = bits[31];
            exp = bits[30:23];
            frac = bits[22:0];

            if (exp == 0) begin
                if (frac == 0)
                    mag = 0.0;
                else
                    mag = (frac / 8388608.0) * (2.0 ** -126);
            end else begin
                mag = (1.0 + frac / 8388608.0) * (2.0 ** (exp - 127));
            end

            fp32_to_real = sign ? -mag : mag;
        end
    endfunction

    function [31:0] real_to_fp32;
        input real val;
        real a;
        real mreal;
        integer sign;
        integer exp_unbiased;
        integer exp_biased;
        integer mant;
        begin
            if (val == 0.0) begin
                real_to_fp32 = 32'h00000000;
            end else begin
                sign = (val < 0.0);
                a = sign ? -val : val;

                exp_unbiased = 0;
                if (a >= 2.0) begin
                    while (a >= (2.0 ** (exp_unbiased + 1)))
                        exp_unbiased = exp_unbiased + 1;
                end else if (a < 1.0) begin
                    while (a < (2.0 ** exp_unbiased))
                        exp_unbiased = exp_unbiased - 1;
                end

                exp_biased = exp_unbiased + 127;

                if (exp_biased <= 0) begin
                    mant = a / (2.0 ** -149) + 0.5;
                    if (mant <= 0)
                        real_to_fp32 = {sign[0], 31'b0};
                    else if (mant > 8388607)
                        real_to_fp32 = {sign[0], 8'b00000000, 23'h7fffff};
                    else
                        real_to_fp32 = {sign[0], 8'b00000000, mant[22:0]};
                end else if (exp_biased >= 255) begin
                    real_to_fp32 = {sign[0], 8'hfe, 23'h7fffff};
                end else begin
                    mreal = (a / (2.0 ** exp_unbiased)) - 1.0;
                    mant = mreal * 8388608.0 + 0.5;

                    if (mant >= 8388608) begin
                        mant = 0;
                        exp_biased = exp_biased + 1;
                    end

                    if (exp_biased >= 255)
                        real_to_fp32 = {sign[0], 8'hfe, 23'h7fffff};
                    else
                        real_to_fp32 = {sign[0], exp_biased[7:0], mant[22:0]};
                end
            end
        end
    endfunction

    real acc;

    always @(posedge clk) begin
        if (rst) begin
            valid_out_r <= 1'b0;
            data_out_r <= 32'h00000000;
            for (i = 0; i < TAP_CNT-1; i = i + 1)
                delay[i] <= 32'h00000000;
        end else begin
            valid_out_r <= valid_in;

            if (valid_in) begin
                acc = fp32_to_real(data_in) * fp32_to_real(coeff[0]);
                for (i = 1; i < TAP_CNT; i = i + 1)
                    acc = acc + fp32_to_real(delay[i-1]) * fp32_to_real(coeff[i]);

                data_out_r <= real_to_fp32(acc);

                delay[0] <= data_in;
                for (i = 1; i < TAP_CNT-1; i = i + 1)
                    delay[i] <= delay[i-1];
            end
        end
    end

endmodule