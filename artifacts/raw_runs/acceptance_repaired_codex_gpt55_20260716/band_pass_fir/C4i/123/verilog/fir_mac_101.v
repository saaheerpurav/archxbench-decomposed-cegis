`timescale 1ns/1ps

module fir_mac_101 #(
    parameter DATA_W = 20,
    parameter TAP_CNT = 101,
    parameter ACC_W = 64
) (
    input signed [DATA_W-1:0] new_sample,
    input signed [DATA_W-1:0] x0,   input signed [DATA_W-1:0] x1,   input signed [DATA_W-1:0] x2,
    input signed [DATA_W-1:0] x3,   input signed [DATA_W-1:0] x4,   input signed [DATA_W-1:0] x5,
    input signed [DATA_W-1:0] x6,   input signed [DATA_W-1:0] x7,   input signed [DATA_W-1:0] x8,
    input signed [DATA_W-1:0] x9,   input signed [DATA_W-1:0] x10,  input signed [DATA_W-1:0] x11,
    input signed [DATA_W-1:0] x12,  input signed [DATA_W-1:0] x13,  input signed [DATA_W-1:0] x14,
    input signed [DATA_W-1:0] x15,  input signed [DATA_W-1:0] x16,  input signed [DATA_W-1:0] x17,
    input signed [DATA_W-1:0] x18,  input signed [DATA_W-1:0] x19,  input signed [DATA_W-1:0] x20,
    input signed [DATA_W-1:0] x21,  input signed [DATA_W-1:0] x22,  input signed [DATA_W-1:0] x23,
    input signed [DATA_W-1:0] x24,  input signed [DATA_W-1:0] x25,  input signed [DATA_W-1:0] x26,
    input signed [DATA_W-1:0] x27,  input signed [DATA_W-1:0] x28,  input signed [DATA_W-1:0] x29,
    input signed [DATA_W-1:0] x30,  input signed [DATA_W-1:0] x31,  input signed [DATA_W-1:0] x32,
    input signed [DATA_W-1:0] x33,  input signed [DATA_W-1:0] x34,  input signed [DATA_W-1:0] x35,
    input signed [DATA_W-1:0] x36,  input signed [DATA_W-1:0] x37,  input signed [DATA_W-1:0] x38,
    input signed [DATA_W-1:0] x39,  input signed [DATA_W-1:0] x40,  input signed [DATA_W-1:0] x41,
    input signed [DATA_W-1:0] x42,  input signed [DATA_W-1:0] x43,  input signed [DATA_W-1:0] x44,
    input signed [DATA_W-1:0] x45,  input signed [DATA_W-1:0] x46,  input signed [DATA_W-1:0] x47,
    input signed [DATA_W-1:0] x48,  input signed [DATA_W-1:0] x49,  input signed [DATA_W-1:0] x50,
    input signed [DATA_W-1:0] x51,  input signed [DATA_W-1:0] x52,  input signed [DATA_W-1:0] x53,
    input signed [DATA_W-1:0] x54,  input signed [DATA_W-1:0] x55,  input signed [DATA_W-1:0] x56,
    input signed [DATA_W-1:0] x57,  input signed [DATA_W-1:0] x58,  input signed [DATA_W-1:0] x59,
    input signed [DATA_W-1:0] x60,  input signed [DATA_W-1:0] x61,  input signed [DATA_W-1:0] x62,
    input signed [DATA_W-1:0] x63,  input signed [DATA_W-1:0] x64,  input signed [DATA_W-1:0] x65,
    input signed [DATA_W-1:0] x66,  input signed [DATA_W-1:0] x67,  input signed [DATA_W-1:0] x68,
    input signed [DATA_W-1:0] x69,  input signed [DATA_W-1:0] x70,  input signed [DATA_W-1:0] x71,
    input signed [DATA_W-1:0] x72,  input signed [DATA_W-1:0] x73,  input signed [DATA_W-1:0] x74,
    input signed [DATA_W-1:0] x75,  input signed [DATA_W-1:0] x76,  input signed [DATA_W-1:0] x77,
    input signed [DATA_W-1:0] x78,  input signed [DATA_W-1:0] x79,  input signed [DATA_W-1:0] x80,
    input signed [DATA_W-1:0] x81,  input signed [DATA_W-1:0] x82,  input signed [DATA_W-1:0] x83,
    input signed [DATA_W-1:0] x84,  input signed [DATA_W-1:0] x85,  input signed [DATA_W-1:0] x86,
    input signed [DATA_W-1:0] x87,  input signed [DATA_W-1:0] x88,  input signed [DATA_W-1:0] x89,
    input signed [DATA_W-1:0] x90,  input signed [DATA_W-1:0] x91,  input signed [DATA_W-1:0] x92,
    input signed [DATA_W-1:0] x93,  input signed [DATA_W-1:0] x94,  input signed [DATA_W-1:0] x95,
    input signed [DATA_W-1:0] x96,  input signed [DATA_W-1:0] x97,  input signed [DATA_W-1:0] x98,
    input signed [DATA_W-1:0] x99,
    output signed [ACC_W-1:0] sum
);

    function signed [15:0] coeff_at;
        input integer idx;
        begin
            case (idx)
                0: coeff_at = 16'sd16; 1: coeff_at = 16'sd10; 2: coeff_at = 16'sd6; 3: coeff_at = 16'sd2;
                4: coeff_at = 16'sd0; 5: coeff_at = 16'sd1; 6: coeff_at = 16'sd5; 7: coeff_at = 16'sd13;
                8: coeff_at = 16'sd26; 9: coeff_at = 16'sd42; 10: coeff_at = 16'sd59; 11: coeff_at = 16'sd77;
                12: coeff_at = 16'sd90; 13: coeff_at = 16'sd97; 14: coeff_at = 16'sd93; 15: coeff_at = 16'sd77;
                16: coeff_at = 16'sd47; 17: coeff_at = 16'sd5; 18: coeff_at = -16'sd45; 19: coeff_at = -16'sd99;
                20: coeff_at = -16'sd149; 21: coeff_at = -16'sd187; 22: coeff_at = -16'sd207; 23: coeff_at = -16'sd204;
                24: coeff_at = -16'sd178; 25: coeff_at = -16'sd132; 26: coeff_at = -16'sd73; 27: coeff_at = -16'sd14;
                28: coeff_at = 16'sd31; 29: coeff_at = 16'sd46; 30: coeff_at = 16'sd16; 31: coeff_at = -16'sd67;
                32: coeff_at = -16'sd208; 33: coeff_at = -16'sd403; 34: coeff_at = -16'sd638; 35: coeff_at = -16'sd891;
                36: coeff_at = -16'sd1134; 37: coeff_at = -16'sd1333; 38: coeff_at = -16'sd1455; 39: coeff_at = -16'sd1471;
                40: coeff_at = -16'sd1359; 41: coeff_at = -16'sd1111; 42: coeff_at = -16'sd730; 43: coeff_at = -16'sd235;
                44: coeff_at = 16'sd341; 45: coeff_at = 16'sd955; 46: coeff_at = 16'sd1555; 47: coeff_at = 16'sd2091;
                48: coeff_at = 16'sd2513; 49: coeff_at = 16'sd2784; 50: coeff_at = 16'sd2877; 51: coeff_at = 16'sd2784;
                52: coeff_at = 16'sd2513; 53: coeff_at = 16'sd2091; 54: coeff_at = 16'sd1555; 55: coeff_at = 16'sd955;
                56: coeff_at = 16'sd341; 57: coeff_at = -16'sd235; 58: coeff_at = -16'sd730; 59: coeff_at = -16'sd1111;
                60: coeff_at = -16'sd1359; 61: coeff_at = -16'sd1471; 62: coeff_at = -16'sd1455; 63: coeff_at = -16'sd1333;
                64: coeff_at = -16'sd1134; 65: coeff_at = -16'sd891; 66: coeff_at = -16'sd638; 67: coeff_at = -16'sd403;
                68: coeff_at = -16'sd208; 69: coeff_at = -16'sd67; 70: coeff_at = 16'sd16; 71: coeff_at = 16'sd46;
                72: coeff_at = 16'sd31; 73: coeff_at = -16'sd14; 74: coeff_at = -16'sd73; 75: coeff_at = -16'sd132;
                76: coeff_at = -16'sd178; 77: coeff_at = -16'sd204; 78: coeff_at = -16'sd207; 79: coeff_at = -16'sd187;
                80: coeff_at = -16'sd149; 81: coeff_at = -16'sd99; 82: coeff_at = -16'sd45; 83: coeff_at = 16'sd5;
                84: coeff_at = 16'sd47; 85: coeff_at = 16'sd77; 86: coeff_at = 16'sd93; 87: coeff_at = 16'sd97;
                88: coeff_at = 16'sd90; 89: coeff_at = 16'sd77; 90: coeff_at = 16'sd59; 91: coeff_at = 16'sd42;
                92: coeff_at = 16'sd26; 93: coeff_at = 16'sd13; 94: coeff_at = 16'sd5; 95: coeff_at = 16'sd1;
                96: coeff_at = 16'sd0; 97: coeff_at = 16'sd2; 98: coeff_at = 16'sd6; 99: coeff_at = 16'sd10;
                100: coeff_at = 16'sd16;
                default: coeff_at = 16'sd0;
            endcase
        end
    endfunction

    wire signed [DATA_W-1:0] sample [0:100];
    assign sample[0] = new_sample;
    assign sample[1] = x0;  assign sample[2] = x1;  assign sample[3] = x2;  assign sample[4] = x3;
    assign sample[5] = x4;  assign sample[6] = x5;  assign sample[7] = x6;  assign sample[8] = x7;
    assign sample[9] = x8;  assign sample[10] = x9; assign sample[11] = x10; assign sample[12] = x11;
    assign sample[13] = x12; assign sample[14] = x13; assign sample[15] = x14; assign sample[16] = x15;
    assign sample[17] = x16; assign sample[18] = x17; assign sample[19] = x18; assign sample[20] = x19;
    assign sample[21] = x20; assign sample[22] = x21; assign sample[23] = x22; assign sample[24] = x23;
    assign sample[25] = x24; assign sample[26] = x25; assign sample[27] = x26; assign sample[28] = x27;
    assign sample[29] = x28; assign sample[30] = x29; assign sample[31] = x30; assign sample[32] = x31;
    assign sample[33] = x32; assign sample[34] = x33; assign sample[35] = x34; assign sample[36] = x35;
    assign sample[37] = x36; assign sample[38] = x37; assign sample[39] = x38; assign sample[40] = x39;
    assign sample[41] = x40; assign sample[42] = x41; assign sample[43] = x42; assign sample[44] = x43;
    assign sample[45] = x44; assign sample[46] = x45; assign sample[47] = x46; assign sample[48] = x47;
    assign sample[49] = x48; assign sample[50] = x49; assign sample[51] = x50; assign sample[52] = x51;
    assign sample[53] = x52; assign sample[54] = x53; assign sample[55] = x54; assign sample[56] = x55;
    assign sample[57] = x56; assign sample[58] = x57; assign sample[59] = x58; assign sample[60] = x59;
    assign sample[61] = x60; assign sample[62] = x61; assign sample[63] = x62; assign sample[64] = x63;
    assign sample[65] = x64; assign sample[66] = x65; assign sample[67] = x66; assign sample[68] = x67;
    assign sample[69] = x68; assign sample[70] = x69; assign sample[71] = x70; assign sample[72] = x71;
    assign sample[73] = x72; assign sample[74] = x73; assign sample[75] = x74; assign sample[76] = x75;
    assign sample[77] = x76; assign sample[78] = x77; assign sample[79] = x78; assign sample[80] = x79;
    assign sample[81] = x80; assign sample[82] = x81; assign sample[83] = x82; assign sample[84] = x83;
    assign sample[85] = x84; assign sample[86] = x85; assign sample[87] = x86; assign sample[88] = x87;
    assign sample[89] = x88; assign sample[90] = x89; assign sample[91] = x90; assign sample[92] = x91;
    assign sample[93] = x92; assign sample[94] = x93; assign sample[95] = x94; assign sample[96] = x95;
    assign sample[97] = x96; assign sample[98] = x97; assign sample[99] = x98; assign sample[100] = x99;

    wire signed [ACC_W-1:0] acc [0:101];
    assign acc[0] = {ACC_W{1'b0}};

    genvar gi;
    generate
        for (gi = 0; gi < 101; gi = gi + 1) begin : gen_mac
            wire signed [15:0] coeff;
            wire signed [ACC_W-1:0] sample_ext;
            wire signed [ACC_W-1:0] coeff_ext;
            wire signed [ACC_W-1:0] product;

            assign coeff = coeff_at(gi);
            assign sample_ext = {{(ACC_W-DATA_W){sample[gi][DATA_W-1]}}, sample[gi]};
            assign coeff_ext  = {{(ACC_W-16){coeff[15]}}, coeff};
            assign product = sample_ext * coeff_ext;
            assign acc[gi+1] = acc[gi] + product;
        end
    endgenerate

    assign sum = acc[101];

endmodule