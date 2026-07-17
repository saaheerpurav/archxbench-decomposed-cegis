`timescale 1ns/1ps

module lowpass_fir #(
    parameter DATA_W  = 20,
    parameter TAP_CNT = 101,
    parameter GAIN_W  = 4
) (
    input                           clk,
    input                           rst,
    input                           valid_in,
    input      [DATA_W-1:0]         data_in,
    output reg                      valid_out,
    output reg [DATA_W+GAIN_W-1:0]  data_out
);

    localparam OUT_W = DATA_W + GAIN_W;

    reg signed [DATA_W-1:0] tap [0:100];
    reg signed [63:0] acc;
    integer i;

    function signed [15:0] coeff;
        input integer idx;
        begin
            case (idx)
                0: coeff = 16'sd0;      1: coeff = -16'sd2;    2: coeff = -16'sd5;
                3: coeff = -16'sd7;     4: coeff = -16'sd10;   5: coeff = -16'sd14;
                6: coeff = -16'sd18;    7: coeff = -16'sd23;   8: coeff = -16'sd29;
                9: coeff = -16'sd35;   10: coeff = -16'sd41;  11: coeff = -16'sd49;
               12: coeff = -16'sd56;   13: coeff = -16'sd63;  14: coeff = -16'sd70;
               15: coeff = -16'sd76;   16: coeff = -16'sd81;  17: coeff = -16'sd85;
               18: coeff = -16'sd86;   19: coeff = -16'sd85;  20: coeff = -16'sd81;
               21: coeff = -16'sd73;   22: coeff = -16'sd62;  23: coeff = -16'sd46;
               24: coeff = -16'sd26;   25: coeff = 16'sd0;    26: coeff = 16'sd31;
               27: coeff = 16'sd67;    28: coeff = 16'sd109;  29: coeff = 16'sd156;
               30: coeff = 16'sd208;   31: coeff = 16'sd266;  32: coeff = 16'sd327;
               33: coeff = 16'sd393;   34: coeff = 16'sd462;  35: coeff = 16'sd534;
               36: coeff = 16'sd607;   37: coeff = 16'sd682;  38: coeff = 16'sd756;
               39: coeff = 16'sd830;   40: coeff = 16'sd901;  41: coeff = 16'sd970;
               42: coeff = 16'sd1034;  43: coeff = 16'sd1094; 44: coeff = 16'sd1147;
               45: coeff = 16'sd1194;  46: coeff = 16'sd1233; 47: coeff = 16'sd1265;
               48: coeff = 16'sd1287;  49: coeff = 16'sd1301; 50: coeff = 16'sd1306;
               51: coeff = 16'sd1301;  52: coeff = 16'sd1287; 53: coeff = 16'sd1265;
               54: coeff = 16'sd1233;  55: coeff = 16'sd1194; 56: coeff = 16'sd1147;
               57: coeff = 16'sd1094;  58: coeff = 16'sd1034; 59: coeff = 16'sd970;
               60: coeff = 16'sd901;   61: coeff = 16'sd830;  62: coeff = 16'sd756;
               63: coeff = 16'sd682;   64: coeff = 16'sd607;  65: coeff = 16'sd534;
               66: coeff = 16'sd462;   67: coeff = 16'sd393;  68: coeff = 16'sd327;
               69: coeff = 16'sd266;   70: coeff = 16'sd208;  71: coeff = 16'sd156;
               72: coeff = 16'sd109;   73: coeff = 16'sd67;   74: coeff = 16'sd31;
               75: coeff = 16'sd0;     76: coeff = -16'sd26;  77: coeff = -16'sd46;
               78: coeff = -16'sd62;   79: coeff = -16'sd73;  80: coeff = -16'sd81;
               81: coeff = -16'sd85;   82: coeff = -16'sd86;  83: coeff = -16'sd85;
               84: coeff = -16'sd81;   85: coeff = -16'sd76;  86: coeff = -16'sd70;
               87: coeff = -16'sd63;   88: coeff = -16'sd56;  89: coeff = -16'sd49;
               90: coeff = -16'sd41;   91: coeff = -16'sd35;  92: coeff = -16'sd29;
               93: coeff = -16'sd23;   94: coeff = -16'sd18;  95: coeff = -16'sd14;
               96: coeff = -16'sd10;   97: coeff = -16'sd7;   98: coeff = -16'sd5;
               99: coeff = -16'sd2;   100: coeff = 16'sd0;
                default: coeff = 16'sd0;
            endcase
        end
    endfunction

    always @(negedge clk) begin
        if (rst) begin
            for (i = 0; i < 101; i = i + 1)
                tap[i] = {DATA_W{1'b0}};
            valid_out = 1'b0;
            data_out  = {OUT_W{1'b0}};
        end else begin
            valid_out = valid_in;

            if (valid_in) begin
                for (i = 100; i > 0; i = i - 1)
                    tap[i] = tap[i-1];
                tap[0] = $signed(data_in);

                acc = 64'sd0;
                for (i = 0; i < 101; i = i + 1)
                    acc = acc + ($signed(tap[i]) * coeff(i));

                data_out = acc >>> 15;
            end
        end
    end

endmodule