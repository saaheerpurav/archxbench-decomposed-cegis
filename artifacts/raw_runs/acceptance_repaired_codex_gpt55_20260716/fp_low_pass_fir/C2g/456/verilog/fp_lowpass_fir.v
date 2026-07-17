`timescale 1ns/1ps

module fp_lowpass_fir #(
    parameter TAP_CNT = 101
) (
    input wire clk,
    input wire rst,
    input wire valid_in,
    input wire [31:0] data_in,
    output wire valid_out,
    output wire [31:0] data_out
);

    reg        valid_q;
    reg [31:0] data_q;
    reg [31:0] delay_line [0:TAP_CNT-1];

    integer i;

    assign valid_out = valid_q;
    assign data_out  = data_q;

    function [31:0] coeff;
        input integer idx;
        begin
            case (idx)
                0: coeff = 32'ha012b177;
                1: coeff = 32'hb8899b4e;
                2: coeff = 32'hb9100cde;
                3: coeff = 32'hb9658a36;
                4: coeff = 32'hb9a46f97;
                5: coeff = 32'hb9de9774;
                6: coeff = 32'hba1138b0;
                7: coeff = 32'hba385a59;
                8: coeff = 32'hba64beaf;
                9: coeff = 32'hba8b0c70;
                10: coeff = 32'hbaa5db4a;
                11: coeff = 32'hbac23c16;
                12: coeff = 32'hbadf6632;
                13: coeff = 32'hbafc57d6;
                14: coeff = 32'hbb0bebe1;
                15: coeff = 32'hbb183c76;
                16: coeff = 32'hbb225021;
                17: coeff = 32'hbb29462d;
                18: coeff = 32'hbb2c2f7f;
                19: coeff = 32'hbb2a1427;
                20: coeff = 32'hbb21f9a9;
                21: coeff = 32'hbb12e9c7;
                22: coeff = 32'hbaf7f357;
                23: coeff = 32'hbab8a276;
                24: coeff = 32'hba4cc970;
                25: coeff = 32'h21778b78;
                26: coeff = 32'h3a76ed36;
                27: coeff = 32'h3b064780;
                28: coeff = 32'h3b59ba00;
                29: coeff = 32'h3b9bf8d7;
                30: coeff = 32'h3bd04a05;
                31: coeff = 32'h3c04c2ee;
                32: coeff = 32'h3c23a218;
                33: coeff = 32'h3c447ffc;
                34: coeff = 32'h3c670c62;
                35: coeff = 32'h3c857531;
                36: coeff = 32'h3c97d8e8;
                37: coeff = 32'h3caa7876;
                38: coeff = 32'h3cbd1733;
                39: coeff = 32'h3ccf75c9;
                40: coeff = 32'h3ce1536a;
                41: coeff = 32'h3cf26f15;
                42: coeff = 32'h3d014471;
                43: coeff = 32'h3d08b1ac;
                44: coeff = 32'h3d0f6255;
                45: coeff = 32'h3d153bfc;
                46: coeff = 32'h3d1a2735;
                47: coeff = 32'h3d1e101a;
                48: coeff = 32'h3d20e6b9;
                49: coeff = 32'h3d229f6d;
                50: coeff = 32'h3d23331f;
                51: coeff = 32'h3d229f6d;
                52: coeff = 32'h3d20e6b9;
                53: coeff = 32'h3d1e101a;
                54: coeff = 32'h3d1a2735;
                55: coeff = 32'h3d153bfc;
                56: coeff = 32'h3d0f6255;
                57: coeff = 32'h3d08b1ac;
                58: coeff = 32'h3d014471;
                59: coeff = 32'h3cf26f15;
                60: coeff = 32'h3ce1536a;
                61: coeff = 32'h3ccf75c9;
                62: coeff = 32'h3cbd1733;
                63: coeff = 32'h3caa7876;
                64: coeff = 32'h3c97d8e8;
                65: coeff = 32'h3c857531;
                66: coeff = 32'h3c670c62;
                67: coeff = 32'h3c447ffc;
                68: coeff = 32'h3c23a218;
                69: coeff = 32'h3c04c2ee;
                70: coeff = 32'h3bd04a05;
                71: coeff = 32'h3b9bf8d7;
                72: coeff = 32'h3b59ba00;
                73: coeff = 32'h3b064780;
                74: coeff = 32'h3a76ed36;
                75: coeff = 32'h21778b78;
                76: coeff = 32'hba4cc970;
                77: coeff = 32'hbab8a276;
                78: coeff = 32'hbaf7f357;
                79: coeff = 32'hbb12e9c7;
                80: coeff = 32'hbb21f9a9;
                81: coeff = 32'hbb2a1427;
                82: coeff = 32'hbb2c2f7f;
                83: coeff = 32'hbb29462d;
                84: coeff = 32'hbb225021;
                85: coeff = 32'hbb183c76;
                86: coeff = 32'hbb0bebe1;
                87: coeff = 32'hbafc57d6;
                88: coeff = 32'hbadf6632;
                89: coeff = 32'hbac23c16;
                90: coeff = 32'hbaa5db4a;
                91: coeff = 32'hba8b0c70;
                92: coeff = 32'hba64beaf;
                93: coeff = 32'hba385a59;
                94: coeff = 32'hba1138b0;
                95: coeff = 32'hb9de9774;
                96: coeff = 32'hb9a46f97;
                97: coeff = 32'hb9658a36;
                98: coeff = 32'hb9100cde;
                99: coeff = 32'hb8899b4e;
                100: coeff = 32'ha012b177;
                default: coeff = 32'h00000000;
            endcase
        end
    endfunction

    function real fp32_to_real;
        input [31:0] bits;
        integer sign;
        integer exp;
        integer frac;
        real mant;
        begin
            sign = bits[31] ? -1 : 1;
            exp  = bits[30:23];
            frac = bits[22:0];

            if (exp == 0 && frac == 0) begin
                fp32_to_real = 0.0;
            end else if (exp == 0) begin
                mant = frac / 8388608.0;
                fp32_to_real = sign * mant * (2.0 ** (-126));
            end else begin
                mant = 1.0 + (frac / 8388608.0);
                fp32_to_real = sign * mant * (2.0 ** (exp - 127));
            end
        end
    endfunction

    function [31:0] real_to_fp32;
        input real val;
        real absval;
        real scaled;
        real frac_real;
        integer sign;
        integer exp_unbiased;
        integer exp_biased;
        integer mant;
        integer guard_val;
        begin
            if (val == 0.0) begin
                real_to_fp32 = 32'h00000000;
            end else begin
                sign = (val < 0.0);
                absval = sign ? -val : val;

                exp_unbiased = 0;
                scaled = absval;

                while (scaled >= 2.0) begin
                    scaled = scaled / 2.0;
                    exp_unbiased = exp_unbiased + 1;
                end

                while (scaled < 1.0) begin
                    scaled = scaled * 2.0;
                    exp_unbiased = exp_unbiased - 1;
                end

                exp_biased = exp_unbiased + 127;

                if (exp_biased <= 0) begin
                    frac_real = absval / (2.0 ** (-149));
                    mant = frac_real;
                    guard_val = ((frac_real - mant) >= 0.5);
                    mant = mant + guard_val;
                    real_to_fp32 = {sign[0], 8'h00, mant[22:0]};
                end else if (exp_biased >= 255) begin
                    real_to_fp32 = {sign[0], 8'hff, 23'h000000};
                end else begin
                    frac_real = (scaled - 1.0) * 8388608.0;
                    mant = frac_real;
                    guard_val = ((frac_real - mant) >= 0.5);
                    mant = mant + guard_val;

                    if (mant >= 8388608) begin
                        mant = 0;
                        exp_biased = exp_biased + 1;
                    end

                    if (exp_biased >= 255)
                        real_to_fp32 = {sign[0], 8'hff, 23'h000000};
                    else
                        real_to_fp32 = {sign[0], exp_biased[7:0], mant[22:0]};
                end
            end
        end
    endfunction

    function [31:0] fir_result;
        input [31:0] newest;
        real acc;
        integer k;
        begin
            acc = fp32_to_real(newest) * fp32_to_real(coeff(0));
            for (k = 1; k < TAP_CNT; k = k + 1)
                acc = acc + fp32_to_real(delay_line[k-1]) * fp32_to_real(coeff(k));
            fir_result = real_to_fp32(acc);
        end
    endfunction

    always @(posedge clk) begin
        if (rst) begin
            valid_q <= 1'b0;
            data_q <= 32'h00000000;
            for (i = 0; i < TAP_CNT; i = i + 1)
                delay_line[i] <= 32'h00000000;
        end else begin
            valid_q <= valid_in;

            if (valid_in) begin
                data_q <= fir_result(data_in);

                for (i = TAP_CNT-1; i > 0; i = i - 1)
                    delay_line[i] <= delay_line[i-1];

                delay_line[0] <= data_in;
            end
        end
    end

endmodule