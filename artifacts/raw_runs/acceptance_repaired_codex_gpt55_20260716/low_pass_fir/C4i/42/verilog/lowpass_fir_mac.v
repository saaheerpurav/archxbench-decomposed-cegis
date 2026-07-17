`timescale 1ns/1ps

module lowpass_fir_mac #(
    parameter DATA_W  = 20,
    parameter TAP_CNT = 101,
    parameter COEFF_W = 16,
    parameter ACC_W   = 64
) (
    input  [DATA_W*TAP_CNT-1:0] sample_bus,
    input  [COEFF_W*((TAP_CNT+1)/2)-1:0] coeff_bus,
    output reg signed [ACC_W-1:0] acc_out
);
    integer i;

    reg signed [DATA_W-1:0] sample;

    function signed [COEFF_W-1:0] hard_coeff;
        input integer idx;
        begin
            case (idx)
                0:   hard_coeff = 16'sd0;
                1:   hard_coeff = -16'sd2;
                2:   hard_coeff = -16'sd5;
                3:   hard_coeff = -16'sd7;
                4:   hard_coeff = -16'sd10;
                5:   hard_coeff = -16'sd14;
                6:   hard_coeff = -16'sd18;
                7:   hard_coeff = -16'sd23;
                8:   hard_coeff = -16'sd29;
                9:   hard_coeff = -16'sd35;
                10:  hard_coeff = -16'sd41;
                11:  hard_coeff = -16'sd49;
                12:  hard_coeff = -16'sd56;
                13:  hard_coeff = -16'sd63;
                14:  hard_coeff = -16'sd70;
                15:  hard_coeff = -16'sd76;
                16:  hard_coeff = -16'sd81;
                17:  hard_coeff = -16'sd85;
                18:  hard_coeff = -16'sd86;
                19:  hard_coeff = -16'sd85;
                20:  hard_coeff = -16'sd81;
                21:  hard_coeff = -16'sd73;
                22:  hard_coeff = -16'sd62;
                23:  hard_coeff = -16'sd46;
                24:  hard_coeff = -16'sd26;
                25:  hard_coeff = 16'sd0;
                26:  hard_coeff = 16'sd31;
                27:  hard_coeff = 16'sd67;
                28:  hard_coeff = 16'sd109;
                29:  hard_coeff = 16'sd156;
                30:  hard_coeff = 16'sd208;
                31:  hard_coeff = 16'sd266;
                32:  hard_coeff = 16'sd327;
                33:  hard_coeff = 16'sd393;
                34:  hard_coeff = 16'sd462;
                35:  hard_coeff = 16'sd534;
                36:  hard_coeff = 16'sd607;
                37:  hard_coeff = 16'sd682;
                38:  hard_coeff = 16'sd756;
                39:  hard_coeff = 16'sd830;
                40:  hard_coeff = 16'sd901;
                41:  hard_coeff = 16'sd970;
                42:  hard_coeff = 16'sd1034;
                43:  hard_coeff = 16'sd1094;
                44:  hard_coeff = 16'sd1147;
                45:  hard_coeff = 16'sd1194;
                46:  hard_coeff = 16'sd1233;
                47:  hard_coeff = 16'sd1265;
                48:  hard_coeff = 16'sd1287;
                49:  hard_coeff = 16'sd1301;
                50:  hard_coeff = 16'sd1306;
                51:  hard_coeff = 16'sd1301;
                52:  hard_coeff = 16'sd1287;
                53:  hard_coeff = 16'sd1265;
                54:  hard_coeff = 16'sd1233;
                55:  hard_coeff = 16'sd1194;
                56:  hard_coeff = 16'sd1147;
                57:  hard_coeff = 16'sd1094;
                58:  hard_coeff = 16'sd1034;
                59:  hard_coeff = 16'sd970;
                60:  hard_coeff = 16'sd901;
                61:  hard_coeff = 16'sd830;
                62:  hard_coeff = 16'sd756;
                63:  hard_coeff = 16'sd682;
                64:  hard_coeff = 16'sd607;
                65:  hard_coeff = 16'sd534;
                66:  hard_coeff = 16'sd462;
                67:  hard_coeff = 16'sd393;
                68:  hard_coeff = 16'sd327;
                69:  hard_coeff = 16'sd266;
                70:  hard_coeff = 16'sd208;
                71:  hard_coeff = 16'sd156;
                72:  hard_coeff = 16'sd109;
                73:  hard_coeff = 16'sd67;
                74:  hard_coeff = 16'sd31;
                75:  hard_coeff = 16'sd0;
                76:  hard_coeff = -16'sd26;
                77:  hard_coeff = -16'sd46;
                78:  hard_coeff = -16'sd62;
                79:  hard_coeff = -16'sd73;
                80:  hard_coeff = -16'sd81;
                81:  hard_coeff = -16'sd85;
                82:  hard_coeff = -16'sd86;
                83:  hard_coeff = -16'sd85;
                84:  hard_coeff = -16'sd81;
                85:  hard_coeff = -16'sd76;
                86:  hard_coeff = -16'sd70;
                87:  hard_coeff = -16'sd63;
                88:  hard_coeff = -16'sd56;
                89:  hard_coeff = -16'sd49;
                90:  hard_coeff = -16'sd41;
                91:  hard_coeff = -16'sd35;
                92:  hard_coeff = -16'sd29;
                93:  hard_coeff = -16'sd23;
                94:  hard_coeff = -16'sd18;
                95:  hard_coeff = -16'sd14;
                96:  hard_coeff = -16'sd10;
                97:  hard_coeff = -16'sd7;
                98:  hard_coeff = -16'sd5;
                99:  hard_coeff = -16'sd2;
                100: hard_coeff = 16'sd0;
                default: hard_coeff = 16'sd0;
            endcase
        end
    endfunction

    always @* begin
        acc_out = {ACC_W{1'b0}};

        for (i = 0; i < TAP_CNT; i = i + 1) begin
            sample = $signed(sample_bus[(TAP_CNT-i)*DATA_W-1 -: DATA_W]);
            acc_out = acc_out + ($signed(sample) * hard_coeff(i));
        end
    end
endmodule