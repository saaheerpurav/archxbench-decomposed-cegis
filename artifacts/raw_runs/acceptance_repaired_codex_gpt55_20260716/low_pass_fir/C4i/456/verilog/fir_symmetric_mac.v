`timescale 1ns/1ps

module fir_symmetric_mac #(
    parameter DATA_W  = 20,
    parameter COEFF_W = 16,
    parameter TAP_CNT = 101,
    parameter ACC_W   = 64
) (
    input  signed [(DATA_W+1)*((TAP_CNT-1)/2)-1:0] pair_sum_bus,
    input  signed [DATA_W-1:0]                     center_sample,
    input  signed [COEFF_W*TAP_CNT-1:0]            coeff_bus,
    output reg signed [ACC_W-1:0]                  accum
);

    localparam PAIR_CNT   = (TAP_CNT - 1) / 2;
    localparam CENTER_IDX = PAIR_CNT;

    integer i;

    reg signed [DATA_W:0]             pair_sum;
    reg signed [DATA_W-1:0]           center_val;
    reg signed [COEFF_W-1:0]          coeff;
    reg signed [DATA_W+COEFF_W:0]     pair_product;
    reg signed [DATA_W+COEFF_W-1:0]   center_product;

    function signed [COEFF_W-1:0] fixed_coeff;
        input integer idx;
        begin
            case (idx)
                0: fixed_coeff = 16'sd0;
                1: fixed_coeff = -16'sd2;
                2: fixed_coeff = -16'sd5;
                3: fixed_coeff = -16'sd7;
                4: fixed_coeff = -16'sd10;
                5: fixed_coeff = -16'sd14;
                6: fixed_coeff = -16'sd18;
                7: fixed_coeff = -16'sd23;
                8: fixed_coeff = -16'sd29;
                9: fixed_coeff = -16'sd35;
                10: fixed_coeff = -16'sd41;
                11: fixed_coeff = -16'sd49;
                12: fixed_coeff = -16'sd56;
                13: fixed_coeff = -16'sd63;
                14: fixed_coeff = -16'sd70;
                15: fixed_coeff = -16'sd76;
                16: fixed_coeff = -16'sd81;
                17: fixed_coeff = -16'sd85;
                18: fixed_coeff = -16'sd86;
                19: fixed_coeff = -16'sd85;
                20: fixed_coeff = -16'sd81;
                21: fixed_coeff = -16'sd73;
                22: fixed_coeff = -16'sd62;
                23: fixed_coeff = -16'sd46;
                24: fixed_coeff = -16'sd26;
                25: fixed_coeff = 16'sd0;
                26: fixed_coeff = 16'sd31;
                27: fixed_coeff = 16'sd67;
                28: fixed_coeff = 16'sd109;
                29: fixed_coeff = 16'sd156;
                30: fixed_coeff = 16'sd208;
                31: fixed_coeff = 16'sd266;
                32: fixed_coeff = 16'sd327;
                33: fixed_coeff = 16'sd393;
                34: fixed_coeff = 16'sd462;
                35: fixed_coeff = 16'sd534;
                36: fixed_coeff = 16'sd607;
                37: fixed_coeff = 16'sd682;
                38: fixed_coeff = 16'sd756;
                39: fixed_coeff = 16'sd830;
                40: fixed_coeff = 16'sd901;
                41: fixed_coeff = 16'sd970;
                42: fixed_coeff = 16'sd1034;
                43: fixed_coeff = 16'sd1094;
                44: fixed_coeff = 16'sd1147;
                45: fixed_coeff = 16'sd1194;
                46: fixed_coeff = 16'sd1233;
                47: fixed_coeff = 16'sd1265;
                48: fixed_coeff = 16'sd1287;
                49: fixed_coeff = 16'sd1301;
                50: fixed_coeff = 16'sd1306;
                default: fixed_coeff = 16'sd0;
            endcase
        end
    endfunction

    always @* begin
        accum = {ACC_W{1'b0}};

        for (i = 0; i < PAIR_CNT; i = i + 1) begin
            pair_sum     = pair_sum_bus[i*(DATA_W+1) +: (DATA_W+1)];
            coeff        = fixed_coeff(i);
            pair_product = pair_sum * coeff;
            accum        = accum + {{(ACC_W-(DATA_W+COEFF_W+1)){pair_product[DATA_W+COEFF_W]}}, pair_product};
        end

        center_val     = center_sample;
        coeff          = fixed_coeff(CENTER_IDX);
        center_product = center_val * coeff;
        accum          = accum + {{(ACC_W-(DATA_W+COEFF_W)){center_product[DATA_W+COEFF_W-1]}}, center_product};
    end

endmodule