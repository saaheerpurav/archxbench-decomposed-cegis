`timescale 1ns/1ps

module fp_bandpass_fir #(
    parameter TAP_CNT = 101
) (
    input wire clk,
    input wire rst,
    input wire valid_in,
    input wire [31:0] data_in,
    output reg valid_out,
    output reg [31:0] data_out
);

    integer i;

    reg [31:0] coeff_bits [0:100];
    real coeff [0:100];
    real hist [0:100];

    real acc;
    real sample_real;

    function real pow2;
        input integer e;
        integer j;
        real v;
        begin
            v = 1.0;
            if (e >= 0) begin
                for (j = 0; j < e; j = j + 1)
                    v = v * 2.0;
            end else begin
                for (j = 0; j < -e; j = j + 1)
                    v = v / 2.0;
            end
            pow2 = v;
        end
    endfunction

    function real bits_to_real32;
        input [31:0] bits;
        integer sign;
        integer exp;
        integer frac;
        real mant;
        begin
            sign = bits[31] ? -1 : 1;
            exp = bits[30:23];
            frac = bits[22:0];

            if (exp == 0) begin
                if (frac == 0)
                    bits_to_real32 = 0.0;
                else
                    bits_to_real32 = sign * (frac / 8388608.0) * pow2(-126);
            end else if (exp == 255) begin
                bits_to_real32 = 0.0;
            end else begin
                mant = 1.0 + (frac / 8388608.0);
                bits_to_real32 = sign * mant * pow2(exp - 127);
            end
        end
    endfunction

    function [31:0] real_to_bits32;
        input real x;
        real ax;
        real mant;
        real frac_real;
        integer sign;
        integer exp_unbiased;
        integer exp_bits;
        integer frac;
        integer rounded;
        begin
            if (x == 0.0) begin
                real_to_bits32 = 32'h00000000;
            end else begin
                sign = (x < 0.0);
                ax = sign ? -x : x;

                exp_unbiased = 0;
                while (ax >= pow2(exp_unbiased + 1))
                    exp_unbiased = exp_unbiased + 1;
                while (ax < pow2(exp_unbiased))
                    exp_unbiased = exp_unbiased - 1;

                exp_bits = exp_unbiased + 127;

                if (exp_bits <= 0) begin
                    frac_real = ax / pow2(-149);
                    rounded = $rtoi(frac_real + 0.5);
                    if (rounded <= 0)
                        real_to_bits32 = {sign[0], 31'h00000000};
                    else if (rounded >= 8388608)
                        real_to_bits32 = {sign[0], 8'd1, 23'd0};
                    else
                        real_to_bits32 = {sign[0], 8'd0, rounded[22:0]};
                end else if (exp_bits >= 255) begin
                    real_to_bits32 = {sign[0], 8'hfe, 23'h7fffff};
                end else begin
                    mant = ax / pow2(exp_unbiased);
                    frac_real = (mant - 1.0) * 8388608.0;
                    rounded = $rtoi(frac_real + 0.5);

                    if (rounded >= 8388608) begin
                        rounded = 0;
                        exp_bits = exp_bits + 1;
                    end

                    if (exp_bits >= 255)
                        real_to_bits32 = {sign[0], 8'hfe, 23'h7fffff};
                    else begin
                        frac = rounded;
                        real_to_bits32 = {sign[0], exp_bits[7:0], frac[22:0]};
                    end
                end
            end
        end
    endfunction

    initial begin
        coeff_bits[  0] = 32'h39fd56aa;
        coeff_bits[  1] = 32'h39a77386;
        coeff_bits[  2] = 32'h39334aac;
        coeff_bits[  3] = 32'h386d8991;
        coeff_bits[  4] = 32'hb5a5aba3;
        coeff_bits[  5] = 32'h37bd8450;
        coeff_bits[  6] = 32'h391fc780;
        coeff_bits[  7] = 32'h39d475a3;
        coeff_bits[  8] = 32'h3a4d6269;
        coeff_bits[  9] = 32'h3aa61be3;
        coeff_bits[ 10] = 32'h3aed3bf0;
        coeff_bits[ 11] = 32'h3b192db6;
        coeff_bits[ 12] = 32'h3b347633;
        coeff_bits[ 13] = 32'h3b418ca6;
        coeff_bits[ 14] = 32'h3b3a03d9;
        coeff_bits[ 15] = 32'h3b193e82;
        coeff_bits[ 16] = 32'h3abb6ece;
        coeff_bits[ 17] = 32'h391fa206;
        coeff_bits[ 18] = 32'hbab5ebf4;
        coeff_bits[ 19] = 32'hbb45facc;
        coeff_bits[ 20] = 32'hbb9488a1;
        coeff_bits[ 21] = 32'hbbbaa786;
        coeff_bits[ 22] = 32'hbbceb76a;
        coeff_bits[ 23] = 32'hbbcc46b2;
        coeff_bits[ 24] = 32'hbbb25119;
        coeff_bits[ 25] = 32'hbb841b84;
        coeff_bits[ 26] = 32'hbb12f16e;
        coeff_bits[ 27] = 32'hb9e522de;
        coeff_bits[ 28] = 32'h3a74a930;
        coeff_bits[ 29] = 32'h3ab63a39;
        coeff_bits[ 30] = 32'h3a034101;
        coeff_bits[ 31] = 32'hbb0600e4;
        coeff_bits[ 32] = 32'hbbd0625a;
        coeff_bits[ 33] = 32'hbc49a519;
        coeff_bits[ 34] = 32'hbc9f93b5;
        coeff_bits[ 35] = 32'hbcdeddd2;
        coeff_bits[ 36] = 32'hbd0dbce0;
        coeff_bits[ 37] = 32'hbd2696ef;
        coeff_bits[ 38] = 32'hbd35d6f1;
        coeff_bits[ 39] = 32'hbd37d430;
        coeff_bits[ 40] = 32'hbd29e7d2;
        coeff_bits[ 41] = 32'hbd0adcc4;
        coeff_bits[ 42] = 32'hbcb67535;
        coeff_bits[ 43] = 32'hbbeaf5be;
        coeff_bits[ 44] = 32'h3c2a8ac6;
        coeff_bits[ 45] = 32'h3ceeaa3c;
        coeff_bits[ 46] = 32'h3d42697f;
        coeff_bits[ 47] = 32'h3d82ae39;
        coeff_bits[ 48] = 32'h3d9d14a6;
        coeff_bits[ 49] = 32'h3dadfa04;
        coeff_bits[ 50] = 32'h3db3ca74;
        coeff_bits[ 51] = 32'h3dadfa04;
        coeff_bits[ 52] = 32'h3d9d14a6;
        coeff_bits[ 53] = 32'h3d82ae39;
        coeff_bits[ 54] = 32'h3d42697f;
        coeff_bits[ 55] = 32'h3ceeaa3c;
        coeff_bits[ 56] = 32'h3c2a8ac6;
        coeff_bits[ 57] = 32'hbbeaf5be;
        coeff_bits[ 58] = 32'hbcb67535;
        coeff_bits[ 59] = 32'hbd0adcc4;
        coeff_bits[ 60] = 32'hbd29e7d2;
        coeff_bits[ 61] = 32'hbd37d430;
        coeff_bits[ 62] = 32'hbd35d6f1;
        coeff_bits[ 63] = 32'hbd2696ef;
        coeff_bits[ 64] = 32'hbd0dbce0;
        coeff_bits[ 65] = 32'hbcdeddd2;
        coeff_bits[ 66] = 32'hbc9f93b5;
        coeff_bits[ 67] = 32'hbc49a519;
        coeff_bits[ 68] = 32'hbbd0625a;
        coeff_bits[ 69] = 32'hbb0600e4;
        coeff_bits[ 70] = 32'h3a034101;
        coeff_bits[ 71] = 32'h3ab63a39;
        coeff_bits[ 72] = 32'h3a74a930;
        coeff_bits[ 73] = 32'hb9e522de;
        coeff_bits[ 74] = 32'hbb12f16e;
        coeff_bits[ 75] = 32'hbb841b84;
        coeff_bits[ 76] = 32'hbbb25119;
        coeff_bits[ 77] = 32'hbbcc46b2;
        coeff_bits[ 78] = 32'hbbceb76a;
        coeff_bits[ 79] = 32'hbbbaa786;
        coeff_bits[ 80] = 32'hbb9488a1;
        coeff_bits[ 81] = 32'hbb45facc;
        coeff_bits[ 82] = 32'hbab5ebf4;
        coeff_bits[ 83] = 32'h391fa206;
        coeff_bits[ 84] = 32'h3abb6ece;
        coeff_bits[ 85] = 32'h3b193e82;
        coeff_bits[ 86] = 32'h3b3a03d9;
        coeff_bits[ 87] = 32'h3b418ca6;
        coeff_bits[ 88] = 32'h3b347633;
        coeff_bits[ 89] = 32'h3b192db6;
        coeff_bits[ 90] = 32'h3aed3bf0;
        coeff_bits[ 91] = 32'h3aa61be3;
        coeff_bits[ 92] = 32'h3a4d6269;
        coeff_bits[ 93] = 32'h39d475a3;
        coeff_bits[ 94] = 32'h391fc780;
        coeff_bits[ 95] = 32'h37bd8450;
        coeff_bits[ 96] = 32'hb5a5aba3;
        coeff_bits[ 97] = 32'h386d8991;
        coeff_bits[ 98] = 32'h39334aac;
        coeff_bits[ 99] = 32'h39a77386;
        coeff_bits[100] = 32'h39fd56aa;

        for (i = 0; i < 101; i = i + 1) begin
            coeff[i] = bits_to_real32(coeff_bits[i]);
            hist[i] = 0.0;
        end

        valid_out = 1'b0;
        data_out = 32'h00000000;
    end

    always @(posedge clk) begin
        if (rst) begin
            valid_out <= 1'b0;
            data_out <= 32'h00000000;
            for (i = 0; i < 101; i = i + 1)
                hist[i] <= 0.0;
        end else begin
            valid_out <= valid_in;

            if (valid_in) begin
                sample_real = bits_to_real32(data_in);
                acc = coeff[0] * sample_real;

                for (i = 1; i < 101; i = i + 1)
                    acc = acc + coeff[i] * hist[i-1];

                data_out <= real_to_bits32(acc);

                for (i = 100; i > 0; i = i - 1)
                    hist[i] <= hist[i-1];
                hist[0] <= sample_real;
            end
        end
    end

endmodule