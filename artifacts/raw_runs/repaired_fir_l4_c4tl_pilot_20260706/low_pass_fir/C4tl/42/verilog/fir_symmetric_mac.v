`timescale 1ns/1ps

module fir_symmetric_mac #(
    parameter DATA_W  = 20,
    parameter TAP_CNT = 101,
    parameter ACC_W   = 64
) (
    input  [((TAP_CNT-1)/2)*(DATA_W+1)-1:0] pair_sum_bus,
    input  [DATA_W-1:0]                     center_sample,
    output reg signed [ACC_W-1:0]           acc_out
);
    localparam PAIR_CNT = (TAP_CNT - 1) / 2;
    localparam SUM_W    = DATA_W + 1;

    integer i;
    reg signed [SUM_W-1:0] pair_sum;
    reg signed [15:0]      coeff;
    reg signed [DATA_W-1:0] center_signed;

    always @* begin
        acc_out = {ACC_W{1'b0}};

        for (i = 0; i < PAIR_CNT; i = i + 1) begin
            pair_sum = pair_sum_bus[i*SUM_W +: SUM_W];
            coeff = coeff_at(i);
            acc_out = acc_out + pair_sum * coeff;
        end

        center_signed = center_sample;
        acc_out = acc_out + center_signed * coeff_at(PAIR_CNT);
    end

    function signed [15:0] coeff_at;
        input integer idx;
        begin
            case (idx)
                0:  coeff_at = 16'sd0;
                1:  coeff_at = -16'sd2;
                2:  coeff_at = -16'sd5;
                3:  coeff_at = -16'sd7;
                4:  coeff_at = -16'sd10;
                5:  coeff_at = -16'sd14;
                6:  coeff_at = -16'sd18;
                7:  coeff_at = -16'sd23;
                8:  coeff_at = -16'sd29;
                9:  coeff_at = -16'sd35;
                10: coeff_at = -16'sd41;
                11: coeff_at = -16'sd49;
                12: coeff_at = -16'sd56;
                13: coeff_at = -16'sd63;
                14: coeff_at = -16'sd70;
                15: coeff_at = -16'sd76;
                16: coeff_at = -16'sd81;
                17: coeff_at = -16'sd85;
                18: coeff_at = -16'sd86;
                19: coeff_at = -16'sd85;
                20: coeff_at = -16'sd81;
                21: coeff_at = -16'sd73;
                22: coeff_at = -16'sd62;
                23: coeff_at = -16'sd46;
                24: coeff_at = -16'sd26;
                25: coeff_at = 16'sd0;
                26: coeff_at = 16'sd31;
                27: coeff_at = 16'sd67;
                28: coeff_at = 16'sd109;
                29: coeff_at = 16'sd156;
                30: coeff_at = 16'sd208;
                31: coeff_at = 16'sd266;
                32: coeff_at = 16'sd327;
                33: coeff_at = 16'sd393;
                34: coeff_at = 16'sd462;
                35: coeff_at = 16'sd534;
                36: coeff_at = 16'sd607;
                37: coeff_at = 16'sd682;
                38: coeff_at = 16'sd756;
                39: coeff_at = 16'sd830;
                40: coeff_at = 16'sd901;
                41: coeff_at = 16'sd970;
                42: coeff_at = 16'sd1034;
                43: coeff_at = 16'sd1094;
                44: coeff_at = 16'sd1147;
                45: coeff_at = 16'sd1194;
                46: coeff_at = 16'sd1233;
                47: coeff_at = 16'sd1265;
                48: coeff_at = 16'sd1287;
                49: coeff_at = 16'sd1301;
                50: coeff_at = 16'sd1306;
                default: coeff_at = 16'sd0;
            endcase
        end
    endfunction
endmodule