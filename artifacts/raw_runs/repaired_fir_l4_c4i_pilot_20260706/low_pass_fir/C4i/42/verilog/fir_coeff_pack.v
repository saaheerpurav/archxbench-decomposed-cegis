`timescale 1ns/1ps

module fir_coeff_pack #(
    parameter TAP_CNT = 101,
    parameter COEFF_W = 21
) (
    output [COEFF_W*TAP_CNT-1:0] coeff_flat
);
    function signed [COEFF_W-1:0] coeff_at;
        input integer idx;
        begin
            case (idx)
                0:   coeff_at = 21'sd0;
                1:   coeff_at = -21'sd64;
                2:   coeff_at = -21'sd160;
                3:   coeff_at = -21'sd224;
                4:   coeff_at = -21'sd320;
                5:   coeff_at = -21'sd448;
                6:   coeff_at = -21'sd576;
                7:   coeff_at = -21'sd736;
                8:   coeff_at = -21'sd928;
                9:   coeff_at = -21'sd1120;
                10:  coeff_at = -21'sd1312;
                11:  coeff_at = -21'sd1568;
                12:  coeff_at = -21'sd1792;
                13:  coeff_at = -21'sd2016;
                14:  coeff_at = -21'sd2240;
                15:  coeff_at = -21'sd2432;
                16:  coeff_at = -21'sd2592;
                17:  coeff_at = -21'sd2720;
                18:  coeff_at = -21'sd2752;
                19:  coeff_at = -21'sd2720;
                20:  coeff_at = -21'sd2592;
                21:  coeff_at = -21'sd2336;
                22:  coeff_at = -21'sd1984;
                23:  coeff_at = -21'sd1472;
                24:  coeff_at = -21'sd832;
                25:  coeff_at = 21'sd0;
                26:  coeff_at = 21'sd992;
                27:  coeff_at = 21'sd2144;
                28:  coeff_at = 21'sd3488;
                29:  coeff_at = 21'sd4992;
                30:  coeff_at = 21'sd6656;
                31:  coeff_at = 21'sd8512;
                32:  coeff_at = 21'sd10464;
                33:  coeff_at = 21'sd12576;
                34:  coeff_at = 21'sd14784;
                35:  coeff_at = 21'sd17088;
                36:  coeff_at = 21'sd19424;
                37:  coeff_at = 21'sd21824;
                38:  coeff_at = 21'sd24192;
                39:  coeff_at = 21'sd26560;
                40:  coeff_at = 21'sd28832;
                41:  coeff_at = 21'sd31040;
                42:  coeff_at = 21'sd33088;
                43:  coeff_at = 21'sd35008;
                44:  coeff_at = 21'sd36704;
                45:  coeff_at = 21'sd38208;
                46:  coeff_at = 21'sd39456;
                47:  coeff_at = 21'sd40480;
                48:  coeff_at = 21'sd41184;
                49:  coeff_at = 21'sd41632;
                50:  coeff_at = 21'sd41792;
                51:  coeff_at = 21'sd41632;
                52:  coeff_at = 21'sd41184;
                53:  coeff_at = 21'sd40480;
                54:  coeff_at = 21'sd39456;
                55:  coeff_at = 21'sd38208;
                56:  coeff_at = 21'sd36704;
                57:  coeff_at = 21'sd35008;
                58:  coeff_at = 21'sd33088;
                59:  coeff_at = 21'sd31040;
                60:  coeff_at = 21'sd28832;
                61:  coeff_at = 21'sd26560;
                62:  coeff_at = 21'sd24192;
                63:  coeff_at = 21'sd21824;
                64:  coeff_at = 21'sd19424;
                65:  coeff_at = 21'sd17088;
                66:  coeff_at = 21'sd14784;
                67:  coeff_at = 21'sd12576;
                68:  coeff_at = 21'sd10464;
                69:  coeff_at = 21'sd8512;
                70:  coeff_at = 21'sd6656;
                71:  coeff_at = 21'sd4992;
                72:  coeff_at = 21'sd3488;
                73:  coeff_at = 21'sd2144;
                74:  coeff_at = 21'sd992;
                75:  coeff_at = 21'sd0;
                76:  coeff_at = -21'sd832;
                77:  coeff_at = -21'sd1472;
                78:  coeff_at = -21'sd1984;
                79:  coeff_at = -21'sd2336;
                80:  coeff_at = -21'sd2592;
                81:  coeff_at = -21'sd2720;
                82:  coeff_at = -21'sd2752;
                83:  coeff_at = -21'sd2720;
                84:  coeff_at = -21'sd2592;
                85:  coeff_at = -21'sd2432;
                86:  coeff_at = -21'sd2240;
                87:  coeff_at = -21'sd2016;
                88:  coeff_at = -21'sd1792;
                89:  coeff_at = -21'sd1568;
                90:  coeff_at = -21'sd1312;
                91:  coeff_at = -21'sd1120;
                92:  coeff_at = -21'sd928;
                93:  coeff_at = -21'sd736;
                94:  coeff_at = -21'sd576;
                95:  coeff_at = -21'sd448;
                96:  coeff_at = -21'sd320;
                97:  coeff_at = -21'sd224;
                98:  coeff_at = -21'sd160;
                99:  coeff_at = -21'sd64;
                100: coeff_at = 21'sd0;
                default: coeff_at = {COEFF_W{1'b0}};
            endcase
        end
    endfunction

    genvar i;
    generate
        for (i = 0; i < TAP_CNT; i = i + 1) begin : COEFF_GEN
            assign coeff_flat[i*COEFF_W +: COEFF_W] = coeff_at(i);
        end
    endgenerate
endmodule