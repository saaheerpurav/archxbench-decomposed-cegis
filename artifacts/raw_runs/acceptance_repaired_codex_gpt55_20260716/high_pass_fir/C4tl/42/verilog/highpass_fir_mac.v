`timescale 1ns/1ps

module highpass_fir_mac #(
    parameter DATA_W  = 20,
    parameter TAP_CNT = 101,
    parameter ACC_W   = 64
) (
    input      [DATA_W*TAP_CNT-1:0] tap_bus,
    output reg signed [ACC_W-1:0] acc_out
);
    integer i;
    reg signed [DATA_W-1:0] sample;
    reg signed [15:0] coeff;

    function signed [15:0] hpf_coeff;
        input integer idx;
        begin
            case (idx)
                0: hpf_coeff = 16'sd0;
                1: hpf_coeff = 16'sd10;
                2: hpf_coeff = 16'sd17;
                3: hpf_coeff = 16'sd19;
                4: hpf_coeff = 16'sd13;
                5: hpf_coeff = 16'sd0;
                6: hpf_coeff = -16'sd16;
                7: hpf_coeff = -16'sd29;
                8: hpf_coeff = -16'sd32;
                9: hpf_coeff = -16'sd23;
                10: hpf_coeff = 16'sd0;
                11: hpf_coeff = 16'sd29;
                12: hpf_coeff = 16'sd53;
                13: hpf_coeff = 16'sd60;
                14: hpf_coeff = 16'sd42;
                15: hpf_coeff = 16'sd0;
                16: hpf_coeff = -16'sd53;
                17: hpf_coeff = -16'sd96;
                18: hpf_coeff = -16'sd107;
                19: hpf_coeff = -16'sd73;
                20: hpf_coeff = 16'sd0;
                21: hpf_coeff = 16'sd90;
                22: hpf_coeff = 16'sd161;
                23: hpf_coeff = 16'sd177;
                24: hpf_coeff = 16'sd121;
                25: hpf_coeff = 16'sd0;
                26: hpf_coeff = -16'sd145;
                27: hpf_coeff = -16'sd258;
                28: hpf_coeff = -16'sd282;
                29: hpf_coeff = -16'sd191;
                30: hpf_coeff = 16'sd0;
                31: hpf_coeff = 16'sd229;
                32: hpf_coeff = 16'sd406;
                33: hpf_coeff = 16'sd444;
                34: hpf_coeff = 16'sd301;
                35: hpf_coeff = 16'sd0;
                36: hpf_coeff = -16'sd365;
                37: hpf_coeff = -16'sd652;
                38: hpf_coeff = -16'sd724;
                39: hpf_coeff = -16'sd499;
                40: hpf_coeff = 16'sd0;
                41: hpf_coeff = 16'sd633;
                42: hpf_coeff = 16'sd1170;
                43: hpf_coeff = 16'sd1355;
                44: hpf_coeff = 16'sd989;
                45: hpf_coeff = 16'sd0;
                46: hpf_coeff = -16'sd1511;
                47: hpf_coeff = -16'sd3280;
                48: hpf_coeff = -16'sd4943;
                49: hpf_coeff = -16'sd6126;
                50: hpf_coeff = 16'sd26219;
                51: hpf_coeff = -16'sd6126;
                52: hpf_coeff = -16'sd4943;
                53: hpf_coeff = -16'sd3280;
                54: hpf_coeff = -16'sd1511;
                55: hpf_coeff = 16'sd0;
                56: hpf_coeff = 16'sd989;
                57: hpf_coeff = 16'sd1355;
                58: hpf_coeff = 16'sd1170;
                59: hpf_coeff = 16'sd633;
                60: hpf_coeff = 16'sd0;
                61: hpf_coeff = -16'sd499;
                62: hpf_coeff = -16'sd724;
                63: hpf_coeff = -16'sd652;
                64: hpf_coeff = -16'sd365;
                65: hpf_coeff = 16'sd0;
                66: hpf_coeff = 16'sd301;
                67: hpf_coeff = 16'sd444;
                68: hpf_coeff = 16'sd406;
                69: hpf_coeff = 16'sd229;
                70: hpf_coeff = 16'sd0;
                71: hpf_coeff = -16'sd191;
                72: hpf_coeff = -16'sd282;
                73: hpf_coeff = -16'sd258;
                74: hpf_coeff = -16'sd145;
                75: hpf_coeff = 16'sd0;
                76: hpf_coeff = 16'sd121;
                77: hpf_coeff = 16'sd177;
                78: hpf_coeff = 16'sd161;
                79: hpf_coeff = 16'sd90;
                80: hpf_coeff = 16'sd0;
                81: hpf_coeff = -16'sd73;
                82: hpf_coeff = -16'sd107;
                83: hpf_coeff = -16'sd96;
                84: hpf_coeff = -16'sd53;
                85: hpf_coeff = 16'sd0;
                86: hpf_coeff = 16'sd42;
                87: hpf_coeff = 16'sd60;
                88: hpf_coeff = 16'sd53;
                89: hpf_coeff = 16'sd29;
                90: hpf_coeff = 16'sd0;
                91: hpf_coeff = -16'sd23;
                92: hpf_coeff = -16'sd32;
                93: hpf_coeff = -16'sd29;
                94: hpf_coeff = -16'sd16;
                95: hpf_coeff = 16'sd0;
                96: hpf_coeff = 16'sd13;
                97: hpf_coeff = 16'sd19;
                98: hpf_coeff = 16'sd17;
                99: hpf_coeff = 16'sd10;
                100: hpf_coeff = 16'sd0;
                default: hpf_coeff = 16'sd0;
            endcase
        end
    endfunction

    always @* begin
        acc_out = {ACC_W{1'b0}};
        for (i = 0; i < TAP_CNT; i = i + 1) begin
            sample = $signed(tap_bus[i*DATA_W +: DATA_W]);
            coeff = hpf_coeff(i);
            acc_out = acc_out + (sample * coeff);
        end
    end
endmodule