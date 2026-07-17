`timescale 1ns/1ps

module fp_fir_mac #(
    parameter TAP_CNT = 101
) (
    input wire [31:0] samples [0:TAP_CNT-1],
    output reg [31:0] result
);

    integer i;
    reg [31:0] coeff_word;
    shortreal acc;
    shortreal sx;
    shortreal sc;
    shortreal prod;

    function [31:0] coeff_at;
        input integer idx;
        begin
            case (idx)
                0: coeff_at = 32'ha012b177;
                1: coeff_at = 32'hb8899b4e;
                2: coeff_at = 32'hb9100cde;
                3: coeff_at = 32'hb9658a36;
                4: coeff_at = 32'hb9a46f97;
                5: coeff_at = 32'hb9de9774;
                6: coeff_at = 32'hba1138b0;
                7: coeff_at = 32'hba385a59;
                8: coeff_at = 32'hba64beaf;
                9: coeff_at = 32'hba8b0c70;
                10: coeff_at = 32'hbaa5db4a;
                11: coeff_at = 32'hbac23c16;
                12: coeff_at = 32'hbadf6632;
                13: coeff_at = 32'hbafc57d6;
                14: coeff_at = 32'hbb0bebe1;
                15: coeff_at = 32'hbb183c76;
                16: coeff_at = 32'hbb225021;
                17: coeff_at = 32'hbb29462d;
                18: coeff_at = 32'hbb2c2f7f;
                19: coeff_at = 32'hbb2a1427;
                20: coeff_at = 32'hbb21f9a9;
                21: coeff_at = 32'hbb12e9c7;
                22: coeff_at = 32'hbaf7f357;
                23: coeff_at = 32'hbab8a276;
                24: coeff_at = 32'hba4cc970;
                25: coeff_at = 32'h21778b78;
                26: coeff_at = 32'h3a76ed36;
                27: coeff_at = 32'h3b064780;
                28: coeff_at = 32'h3b59ba00;
                29: coeff_at = 32'h3b9bf8d7;
                30: coeff_at = 32'h3bd04a05;
                31: coeff_at = 32'h3c04c2ee;
                32: coeff_at = 32'h3c23a218;
                33: coeff_at = 32'h3c447ffc;
                34: coeff_at = 32'h3c670c62;
                35: coeff_at = 32'h3c857531;
                36: coeff_at = 32'h3c97d8e8;
                37: coeff_at = 32'h3caa7876;
                38: coeff_at = 32'h3cbd1733;
                39: coeff_at = 32'h3ccf75c9;
                40: coeff_at = 32'h3ce1536a;
                41: coeff_at = 32'h3cf26f15;
                42: coeff_at = 32'h3d014471;
                43: coeff_at = 32'h3d08b1ac;
                44: coeff_at = 32'h3d0f6255;
                45: coeff_at = 32'h3d153bfc;
                46: coeff_at = 32'h3d1a2735;
                47: coeff_at = 32'h3d1e101a;
                48: coeff_at = 32'h3d20e6b9;
                49: coeff_at = 32'h3d229f6d;
                50: coeff_at = 32'h3d23331f;
                51: coeff_at = 32'h3d229f6d;
                52: coeff_at = 32'h3d20e6b9;
                53: coeff_at = 32'h3d1e101a;
                54: coeff_at = 32'h3d1a2735;
                55: coeff_at = 32'h3d153bfc;
                56: coeff_at = 32'h3d0f6255;
                57: coeff_at = 32'h3d08b1ac;
                58: coeff_at = 32'h3d014471;
                59: coeff_at = 32'h3cf26f15;
                60: coeff_at = 32'h3ce1536a;
                61: coeff_at = 32'h3ccf75c9;
                62: coeff_at = 32'h3cbd1733;
                63: coeff_at = 32'h3caa7876;
                64: coeff_at = 32'h3c97d8e8;
                65: coeff_at = 32'h3c857531;
                66: coeff_at = 32'h3c670c62;
                67: coeff_at = 32'h3c447ffc;
                68: coeff_at = 32'h3c23a218;
                69: coeff_at = 32'h3c04c2ee;
                70: coeff_at = 32'h3bd04a05;
                71: coeff_at = 32'h3b9bf8d7;
                72: coeff_at = 32'h3b59ba00;
                73: coeff_at = 32'h3b064780;
                74: coeff_at = 32'h3a76ed36;
                75: coeff_at = 32'h21778b78;
                76: coeff_at = 32'hba4cc970;
                77: coeff_at = 32'hbab8a276;
                78: coeff_at = 32'hbaf7f357;
                79: coeff_at = 32'hbb12e9c7;
                80: coeff_at = 32'hbb21f9a9;
                81: coeff_at = 32'hbb2a1427;
                82: coeff_at = 32'hbb2c2f7f;
                83: coeff_at = 32'hbb29462d;
                84: coeff_at = 32'hbb225021;
                85: coeff_at = 32'hbb183c76;
                86: coeff_at = 32'hbb0bebe1;
                87: coeff_at = 32'hbafc57d6;
                88: coeff_at = 32'hbadf6632;
                89: coeff_at = 32'hbac23c16;
                90: coeff_at = 32'hbaa5db4a;
                91: coeff_at = 32'hba8b0c70;
                92: coeff_at = 32'hba64beaf;
                93: coeff_at = 32'hba385a59;
                94: coeff_at = 32'hba1138b0;
                95: coeff_at = 32'hb9de9774;
                96: coeff_at = 32'hb9a46f97;
                97: coeff_at = 32'hb9658a36;
                98: coeff_at = 32'hb9100cde;
                99: coeff_at = 32'hb8899b4e;
                100: coeff_at = 32'ha012b177;
                default: coeff_at = 32'h00000000;
            endcase
        end
    endfunction

    always @* begin
        acc = $bitstoshortreal(32'h00000000);
        for (i = 0; i < TAP_CNT; i = i + 1) begin
            coeff_word = coeff_at(i);
            sx = $bitstoshortreal(samples[i]);
            sc = $bitstoshortreal(coeff_word);
            prod = sx * sc;
            acc = acc + prod;
        end
        result = $shortrealtobits(acc);
        if (result == 32'h80000000)
            result = 32'h00000000;
    end

endmodule