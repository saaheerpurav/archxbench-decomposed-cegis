`timescale 1ns/1ps

module fp_highpass_fir #(
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

    assign valid_out = valid_out_r;
    assign data_out = data_out_r;

    real x_hist [0:TAP_CNT-1];
    real coeff  [0:TAP_CNT-1];

    integer i;

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
        real val;
        begin
            sign = bits[31] ? -1 : 1;
            exp = bits[30:23];
            frac = bits[22:0];

            if (exp == 0) begin
                if (frac == 0)
                    val = 0.0;
                else
                    val = sign * (frac / 8388608.0) * pow2(-126);
            end else begin
                mant = 1.0 + (frac / 8388608.0);
                val = sign * mant * pow2(exp - 127);
            end

            bits_to_real32 = val;
        end
    endfunction

    function [31:0] real_to_bits32;
        input real val;
        reg sign;
        real a;
        integer exp_unbiased;
        integer exp_biased;
        real scaled;
        real frac_real;
        integer frac_floor;
        integer frac;
        real rem;
        begin
            if (val == 0.0) begin
                real_to_bits32 = 32'h00000000;
            end else begin
                sign = (val < 0.0);
                a = sign ? -val : val;

                exp_unbiased = 0;

                if (a >= 2.0) begin
                    while (a >= pow2(exp_unbiased + 1))
                        exp_unbiased = exp_unbiased + 1;
                end else if (a < 1.0) begin
                    while (a < pow2(exp_unbiased))
                        exp_unbiased = exp_unbiased - 1;
                end

                exp_biased = exp_unbiased + 127;

                if (exp_biased <= 0) begin
                    frac_real = a / pow2(-149);
                    frac_floor = frac_real;
                    rem = frac_real - frac_floor;

                    if (rem > 0.5)
                        frac = frac_floor + 1;
                    else if (rem < 0.5)
                        frac = frac_floor;
                    else
                        frac = frac_floor[0] ? frac_floor + 1 : frac_floor;

                    if (frac <= 0)
                        real_to_bits32 = {sign, 31'h00000000};
                    else if (frac >= 8388608)
                        real_to_bits32 = {sign, 8'd1, 23'd0};
                    else
                        real_to_bits32 = {sign, 8'd0, frac[22:0]};
                end else if (exp_biased >= 255) begin
                    real_to_bits32 = {sign, 8'hfe, 23'h7fffff};
                end else begin
                    scaled = a / pow2(exp_unbiased);
                    frac_real = (scaled - 1.0) * 8388608.0;
                    frac_floor = frac_real;
                    rem = frac_real - frac_floor;

                    if (rem > 0.5)
                        frac = frac_floor + 1;
                    else if (rem < 0.5)
                        frac = frac_floor;
                    else
                        frac = frac_floor[0] ? frac_floor + 1 : frac_floor;

                    if (frac == 8388608) begin
                        frac = 0;
                        exp_biased = exp_biased + 1;
                    end

                    if (exp_biased >= 255)
                        real_to_bits32 = {sign, 8'hfe, 23'h7fffff};
                    else
                        real_to_bits32 = {sign, exp_biased[7:0], frac[22:0]};
                end
            end
        end
    endfunction

    function real coeff_by_index;
        input integer idx;
        begin
            case (idx)
                0: coeff_by_index = bits_to_real32(32'h21a5e407);
                1: coeff_by_index = bits_to_real32(32'h39a1fef1);
                2: coeff_by_index = bits_to_real32(32'h3a0a48e5);
                3: coeff_by_index = bits_to_real32(32'h3a14dc7c);
                4: coeff_by_index = bits_to_real32(32'h39c9729c);
                5: coeff_by_index = bits_to_real32(32'h21373cac);
                6: coeff_by_index = bits_to_real32(32'hb9fa686f);
                7: coeff_by_index = bits_to_real32(32'hba647ae3);
                8: coeff_by_index = bits_to_real32(32'hba815b49);
                9: coeff_by_index = bits_to_real32(32'hba3564bc);
                10: coeff_by_index = bits_to_real32(32'ha2c126e6);
                11: coeff_by_index = bits_to_real32(32'h3a696787);
                12: coeff_by_index = bits_to_real32(32'h3ad5c178);
                13: coeff_by_index = bits_to_real32(32'h3af17343);
                14: coeff_by_index = bits_to_real32(32'h3aa82360);
                15: coeff_by_index = bits_to_real32(32'h239ded49);
                16: coeff_by_index = bits_to_real32(32'hbad3be22);
                17: coeff_by_index = bits_to_real32(32'hbb3f7379);
                18: coeff_by_index = bits_to_real32(32'hbb556676);
                19: coeff_by_index = bits_to_real32(32'hbb12a289);
                20: coeff_by_index = bits_to_real32(32'ha4439339);
                21: coeff_by_index = bits_to_real32(32'h3b33fb1e);
                22: coeff_by_index = bits_to_real32(32'h3ba0cd0c);
                23: coeff_by_index = bits_to_real32(32'h3bb13ea7);
                24: coeff_by_index = bits_to_real32(32'h3b71153f);
                25: coeff_by_index = bits_to_real32(32'ha30bf866);
                26: coeff_by_index = bits_to_real32(32'hbb915883);
                27: coeff_by_index = bits_to_real32(32'hbc00e7a5);
                28: coeff_by_index = bits_to_real32(32'hbc0d333a);
                29: coeff_by_index = bits_to_real32(32'hbbbf1429);
                30: coeff_by_index = bits_to_real32(32'ha3c43dcb);
                31: coeff_by_index = bits_to_real32(32'h3be4ec47);
                32: coeff_by_index = bits_to_real32(32'h3c4accff);
                33: coeff_by_index = bits_to_real32(32'h3c5e3e69);
                34: coeff_by_index = bits_to_real32(32'h3c16b483);
                35: coeff_by_index = bits_to_real32(32'h24c72eb7);
                36: coeff_by_index = bits_to_real32(32'hbc367814);
                37: coeff_by_index = bits_to_real32(32'hbca31ca3);
                38: coeff_by_index = bits_to_real32(32'hbcb4ed9c);
                39: coeff_by_index = bits_to_real32(32'hbc794bfe);
                40: coeff_by_index = bits_to_real32(32'ha403343e);
                41: coeff_by_index = bits_to_real32(32'h3c9e21ad);
                42: coeff_by_index = bits_to_real32(32'h3d1233f3);
                43: coeff_by_index = bits_to_real32(32'h3d2969d5);
                44: coeff_by_index = bits_to_real32(32'h3cf73d64);
                45: coeff_by_index = bits_to_real32(32'h240c9a35);
                46: coeff_by_index = bits_to_real32(32'hbd3cd9b8);
                47: coeff_by_index = bits_to_real32(32'hbdcd0395);
                48: coeff_by_index = bits_to_real32(32'hbe1a7617);
                49: coeff_by_index = bits_to_real32(32'hbe3f721e);
                50: coeff_by_index = bits_to_real32(32'h3f4cd56c);
                51: coeff_by_index = bits_to_real32(32'hbe3f721e);
                52: coeff_by_index = bits_to_real32(32'hbe1a7617);
                53: coeff_by_index = bits_to_real32(32'hbdcd0395);
                54: coeff_by_index = bits_to_real32(32'hbd3cd9b8);
                55: coeff_by_index = bits_to_real32(32'h240c9a35);
                56: coeff_by_index = bits_to_real32(32'h3cf73d64);
                57: coeff_by_index = bits_to_real32(32'h3d2969d5);
                58: coeff_by_index = bits_to_real32(32'h3d1233f3);
                59: coeff_by_index = bits_to_real32(32'h3c9e21ad);
                60: coeff_by_index = bits_to_real32(32'ha403343e);
                61: coeff_by_index = bits_to_real32(32'hbc794bfe);
                62: coeff_by_index = bits_to_real32(32'hbcb4ed9c);
                63: coeff_by_index = bits_to_real32(32'hbca31ca3);
                64: coeff_by_index = bits_to_real32(32'hbc367814);
                65: coeff_by_index = bits_to_real32(32'h24c72eb7);
                66: coeff_by_index = bits_to_real32(32'h3c16b483);
                67: coeff_by_index = bits_to_real32(32'h3c5e3e69);
                68: coeff_by_index = bits_to_real32(32'h3c4accff);
                69: coeff_by_index = bits_to_real32(32'h3be4ec47);
                70: coeff_by_index = bits_to_real32(32'ha3c43dcb);
                71: coeff_by_index = bits_to_real32(32'hbbbf1429);
                72: coeff_by_index = bits_to_real32(32'hbc0d333a);
                73: coeff_by_index = bits_to_real32(32'hbc00e7a5);
                74: coeff_by_index = bits_to_real32(32'hbb915883);
                75: coeff_by_index = bits_to_real32(32'ha30bf866);
                76: coeff_by_index = bits_to_real32(32'h3b71153f);
                77: coeff_by_index = bits_to_real32(32'h3bb13ea7);
                78: coeff_by_index = bits_to_real32(32'h3ba0cd0c);
                79: coeff_by_index = bits_to_real32(32'h3b33fb1e);
                80: coeff_by_index = bits_to_real32(32'ha4439339);
                81: coeff_by_index = bits_to_real32(32'hbb12a289);
                82: coeff_by_index = bits_to_real32(32'hbb556676);
                83: coeff_by_index = bits_to_real32(32'hbb3f7379);
                84: coeff_by_index = bits_to_real32(32'hbad3be22);
                85: coeff_by_index = bits_to_real32(32'h239ded49);
                86: coeff_by_index = bits_to_real32(32'h3aa82360);
                87: coeff_by_index = bits_to_real32(32'h3af17343);
                88: coeff_by_index = bits_to_real32(32'h3ad5c178);
                89: coeff_by_index = bits_to_real32(32'h3a696787);
                90: coeff_by_index = bits_to_real32(32'ha2c126e6);
                91: coeff_by_index = bits_to_real32(32'hba3564bc);
                92: coeff_by_index = bits_to_real32(32'hba815b49);
                93: coeff_by_index = bits_to_real32(32'hba647ae3);
                94: coeff_by_index = bits_to_real32(32'hb9fa686f);
                95: coeff_by_index = bits_to_real32(32'h21373cac);
                96: coeff_by_index = bits_to_real32(32'h39c9729c);
                97: coeff_by_index = bits_to_real32(32'h3a14dc7c);
                98: coeff_by_index = bits_to_real32(32'h3a0a48e5);
                99: coeff_by_index = bits_to_real32(32'h39a1fef1);
                100: coeff_by_index = bits_to_real32(32'h21a5e407);
                default: coeff_by_index = 0.0;
            endcase
        end
    endfunction

    initial begin
        for (i = 0; i < TAP_CNT; i = i + 1) begin
            x_hist[i] = 0.0;
            coeff[i] = coeff_by_index(i);
        end
        valid_out_r = 1'b0;
        data_out_r = 32'h00000000;
    end

    real acc;
    real sample;

    always @(posedge clk) begin
        if (rst) begin
            valid_out_r <= 1'b0;
            data_out_r <= 32'h00000000;
            for (i = 0; i < TAP_CNT; i = i + 1)
                x_hist[i] <= 0.0;
        end else begin
            valid_out_r <= valid_in;

            if (valid_in) begin
                sample = bits_to_real32(data_in);
                acc = coeff[0] * sample;

                for (i = 1; i < TAP_CNT; i = i + 1)
                    acc = acc + coeff[i] * x_hist[i-1];

                data_out_r <= real_to_bits32(acc);

                for (i = TAP_CNT-1; i > 0; i = i - 1)
                    x_hist[i] <= x_hist[i-1];

                x_hist[0] <= sample;
            end
        end
    end

endmodule