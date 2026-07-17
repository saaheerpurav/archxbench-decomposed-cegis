`timescale 1ns/1ps

module highpass_fir #(
    parameter DATA_W  = 20,
    parameter TAP_CNT = 101,
    parameter GAIN_W  = 4
) (
    input                           clk,
    input                           rst,
    input                           valid_in,
    input      [DATA_W-1:0]         data_in,
    output                          valid_out,
    output     [DATA_W+GAIN_W-1:0]  data_out
);

    localparam OUT_W = DATA_W + GAIN_W;

    reg signed [DATA_W-1:0] delay_line [0:99];

    integer i;
    integer k;

    reg signed [63:0] acc;
    reg signed [63:0] x_ext;
    reg signed [63:0] c_ext;
    reg signed [15:0] c;
    reg signed [OUT_W-1:0] y;

    assign valid_out = valid_in;
    assign data_out  = valid_in ? y : {OUT_W{1'b0}};

    function signed [15:0] coeff;
        input integer idx;
        begin
            case (idx)
                0: coeff = 16'sd0;
                1: coeff = 16'sd10;
                2: coeff = 16'sd17;
                3: coeff = 16'sd19;
                4: coeff = 16'sd13;
                5: coeff = 16'sd0;
                6: coeff = -16'sd16;
                7: coeff = -16'sd29;
                8: coeff = -16'sd32;
                9: coeff = -16'sd23;
                10: coeff = 16'sd0;
                11: coeff = 16'sd29;
                12: coeff = 16'sd53;
                13: coeff = 16'sd60;
                14: coeff = 16'sd42;
                15: coeff = 16'sd0;
                16: coeff = -16'sd53;
                17: coeff = -16'sd96;
                18: coeff = -16'sd107;
                19: coeff = -16'sd73;
                20: coeff = 16'sd0;
                21: coeff = 16'sd90;
                22: coeff = 16'sd161;
                23: coeff = 16'sd177;
                24: coeff = 16'sd121;
                25: coeff = 16'sd0;
                26: coeff = -16'sd145;
                27: coeff = -16'sd258;
                28: coeff = -16'sd282;
                29: coeff = -16'sd191;
                30: coeff = 16'sd0;
                31: coeff = 16'sd229;
                32: coeff = 16'sd406;
                33: coeff = 16'sd444;
                34: coeff = 16'sd301;
                35: coeff = 16'sd0;
                36: coeff = -16'sd365;
                37: coeff = -16'sd652;
                38: coeff = -16'sd724;
                39: coeff = -16'sd499;
                40: coeff = 16'sd0;
                41: coeff = 16'sd633;
                42: coeff = 16'sd1170;
                43: coeff = 16'sd1355;
                44: coeff = 16'sd989;
                45: coeff = 16'sd0;
                46: coeff = -16'sd1511;
                47: coeff = -16'sd3280;
                48: coeff = -16'sd4943;
                49: coeff = -16'sd6126;
                50: coeff = 16'sd26219;
                51: coeff = -16'sd6126;
                52: coeff = -16'sd4943;
                53: coeff = -16'sd3280;
                54: coeff = -16'sd1511;
                55: coeff = 16'sd0;
                56: coeff = 16'sd989;
                57: coeff = 16'sd1355;
                58: coeff = 16'sd1170;
                59: coeff = 16'sd633;
                60: coeff = 16'sd0;
                61: coeff = -16'sd499;
                62: coeff = -16'sd724;
                63: coeff = -16'sd652;
                64: coeff = -16'sd365;
                65: coeff = 16'sd0;
                66: coeff = 16'sd301;
                67: coeff = 16'sd444;
                68: coeff = 16'sd406;
                69: coeff = 16'sd229;
                70: coeff = 16'sd0;
                71: coeff = -16'sd191;
                72: coeff = -16'sd282;
                73: coeff = -16'sd258;
                74: coeff = -16'sd145;
                75: coeff = 16'sd0;
                76: coeff = 16'sd121;
                77: coeff = 16'sd177;
                78: coeff = 16'sd161;
                79: coeff = 16'sd90;
                80: coeff = 16'sd0;
                81: coeff = -16'sd73;
                82: coeff = -16'sd107;
                83: coeff = -16'sd96;
                84: coeff = -16'sd53;
                85: coeff = 16'sd0;
                86: coeff = 16'sd42;
                87: coeff = 16'sd60;
                88: coeff = 16'sd53;
                89: coeff = 16'sd29;
                90: coeff = 16'sd0;
                91: coeff = -16'sd23;
                92: coeff = -16'sd32;
                93: coeff = -16'sd29;
                94: coeff = -16'sd16;
                95: coeff = 16'sd0;
                96: coeff = 16'sd13;
                97: coeff = 16'sd19;
                98: coeff = 16'sd17;
                99: coeff = 16'sd10;
                100: coeff = 16'sd0;
                default: coeff = 16'sd0;
            endcase
        end
    endfunction

    always @* begin
        acc = 64'sd0;

        for (k = 0; k < 101; k = k + 1) begin
            if (k == 0)
                x_ext = {{(64-DATA_W){data_in[DATA_W-1]}}, data_in};
            else
                x_ext = {{(64-DATA_W){delay_line[k-1][DATA_W-1]}}, delay_line[k-1]};

            c = coeff(k);
            c_ext = {{48{c[15]}}, c};
            acc = acc + (x_ext * c_ext);
        end

        y = acc >>> 15;
    end

    always @(negedge clk) begin
        if (rst) begin
            for (i = 0; i < 100; i = i + 1)
                delay_line[i] <= {DATA_W{1'b0}};
        end else if (valid_in) begin
            delay_line[0] <= $signed(data_in);
            for (i = 1; i < 100; i = i + 1)
                delay_line[i] <= delay_line[i-1];
        end
    end

endmodule