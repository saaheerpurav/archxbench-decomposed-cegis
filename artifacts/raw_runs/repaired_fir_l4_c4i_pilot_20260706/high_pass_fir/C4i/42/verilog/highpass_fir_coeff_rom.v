`timescale 1ns/1ps

module highpass_fir_coeff_rom #(
    parameter TAP_CNT = 101
) (
    output [16*TAP_CNT-1:0] coeffs_flat
);

    function signed [15:0] coeff_at;
        input integer idx;
        begin
            case (idx)
                0:   coeff_at = 16'sd0;
                1:   coeff_at = 16'sd10;
                2:   coeff_at = 16'sd17;
                3:   coeff_at = 16'sd19;
                4:   coeff_at = 16'sd13;
                5:   coeff_at = 16'sd0;
                6:   coeff_at = -16'sd16;
                7:   coeff_at = -16'sd29;
                8:   coeff_at = -16'sd32;
                9:   coeff_at = -16'sd23;
                10:  coeff_at = 16'sd0;
                11:  coeff_at = 16'sd29;
                12:  coeff_at = 16'sd53;
                13:  coeff_at = 16'sd60;
                14:  coeff_at = 16'sd42;
                15:  coeff_at = 16'sd0;
                16:  coeff_at = -16'sd53;
                17:  coeff_at = -16'sd96;
                18:  coeff_at = -16'sd107;
                19:  coeff_at = -16'sd73;
                20:  coeff_at = 16'sd0;
                21:  coeff_at = 16'sd90;
                22:  coeff_at = 16'sd161;
                23:  coeff_at = 16'sd177;
                24:  coeff_at = 16'sd121;
                25:  coeff_at = 16'sd0;
                26:  coeff_at = -16'sd145;
                27:  coeff_at = -16'sd258;
                28:  coeff_at = -16'sd282;
                29:  coeff_at = -16'sd191;
                30:  coeff_at = 16'sd0;
                31:  coeff_at = 16'sd229;
                32:  coeff_at = 16'sd406;
                33:  coeff_at = 16'sd444;
                34:  coeff_at = 16'sd301;
                35:  coeff_at = 16'sd0;
                36:  coeff_at = -16'sd365;
                37:  coeff_at = -16'sd652;
                38:  coeff_at = -16'sd724;
                39:  coeff_at = -16'sd499;
                40:  coeff_at = 16'sd0;
                41:  coeff_at = 16'sd633;
                42:  coeff_at = 16'sd1170;
                43:  coeff_at = 16'sd1355;
                44:  coeff_at = 16'sd989;
                45:  coeff_at = 16'sd0;
                46:  coeff_at = -16'sd1511;
                47:  coeff_at = -16'sd3280;
                48:  coeff_at = -16'sd4943;
                49:  coeff_at = -16'sd6126;
                50:  coeff_at = 16'sd26219;
                51:  coeff_at = -16'sd6126;
                52:  coeff_at = -16'sd4943;
                53:  coeff_at = -16'sd3280;
                54:  coeff_at = -16'sd1511;
                55:  coeff_at = 16'sd0;
                56:  coeff_at = 16'sd989;
                57:  coeff_at = 16'sd1355;
                58:  coeff_at = 16'sd1170;
                59:  coeff_at = 16'sd633;
                60:  coeff_at = 16'sd0;
                61:  coeff_at = -16'sd499;
                62:  coeff_at = -16'sd724;
                63:  coeff_at = -16'sd652;
                64:  coeff_at = -16'sd365;
                65:  coeff_at = 16'sd0;
                66:  coeff_at = 16'sd301;
                67:  coeff_at = 16'sd444;
                68:  coeff_at = 16'sd406;
                69:  coeff_at = 16'sd229;
                70:  coeff_at = 16'sd0;
                71:  coeff_at = -16'sd191;
                72:  coeff_at = -16'sd282;
                73:  coeff_at = -16'sd258;
                74:  coeff_at = -16'sd145;
                75:  coeff_at = 16'sd0;
                76:  coeff_at = 16'sd121;
                77:  coeff_at = 16'sd177;
                78:  coeff_at = 16'sd161;
                79:  coeff_at = 16'sd90;
                80:  coeff_at = 16'sd0;
                81:  coeff_at = -16'sd73;
                82:  coeff_at = -16'sd107;
                83:  coeff_at = -16'sd96;
                84:  coeff_at = -16'sd53;
                85:  coeff_at = 16'sd0;
                86:  coeff_at = 16'sd42;
                87:  coeff_at = 16'sd60;
                88:  coeff_at = 16'sd53;
                89:  coeff_at = 16'sd29;
                90:  coeff_at = 16'sd0;
                91:  coeff_at = -16'sd23;
                92:  coeff_at = -16'sd32;
                93:  coeff_at = -16'sd29;
                94:  coeff_at = -16'sd16;
                95:  coeff_at = 16'sd0;
                96:  coeff_at = 16'sd13;
                97:  coeff_at = 16'sd19;
                98:  coeff_at = 16'sd17;
                99:  coeff_at = 16'sd10;
                100: coeff_at = 16'sd0;
                default: coeff_at = 16'sd0;
            endcase
        end
    endfunction

    genvar i;
    generate
        for (i = 0; i < TAP_CNT; i = i + 1) begin : COEFF_PACK
            assign coeffs_flat[(i+1)*16-1:i*16] = coeff_at(i);
        end
    endgenerate

endmodule