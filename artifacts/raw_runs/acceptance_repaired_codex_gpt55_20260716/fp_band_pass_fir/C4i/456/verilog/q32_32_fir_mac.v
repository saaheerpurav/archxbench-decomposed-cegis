`timescale 1ns/1ps

module q32_32_fir_mac #(
    parameter TAP_CNT = 101
) (
    input wire signed [63:0] x0, input wire signed [63:0] x1,
    input wire signed [63:0] x2, input wire signed [63:0] x3,
    input wire signed [63:0] x4, input wire signed [63:0] x5,
    input wire signed [63:0] x6, input wire signed [63:0] x7,
    input wire signed [63:0] x8, input wire signed [63:0] x9,
    input wire signed [63:0] x10, input wire signed [63:0] x11,
    input wire signed [63:0] x12, input wire signed [63:0] x13,
    input wire signed [63:0] x14, input wire signed [63:0] x15,
    input wire signed [63:0] x16, input wire signed [63:0] x17,
    input wire signed [63:0] x18, input wire signed [63:0] x19,
    input wire signed [63:0] x20, input wire signed [63:0] x21,
    input wire signed [63:0] x22, input wire signed [63:0] x23,
    input wire signed [63:0] x24, input wire signed [63:0] x25,
    input wire signed [63:0] x26, input wire signed [63:0] x27,
    input wire signed [63:0] x28, input wire signed [63:0] x29,
    input wire signed [63:0] x30, input wire signed [63:0] x31,
    input wire signed [63:0] x32, input wire signed [63:0] x33,
    input wire signed [63:0] x34, input wire signed [63:0] x35,
    input wire signed [63:0] x36, input wire signed [63:0] x37,
    input wire signed [63:0] x38, input wire signed [63:0] x39,
    input wire signed [63:0] x40, input wire signed [63:0] x41,
    input wire signed [63:0] x42, input wire signed [63:0] x43,
    input wire signed [63:0] x44, input wire signed [63:0] x45,
    input wire signed [63:0] x46, input wire signed [63:0] x47,
    input wire signed [63:0] x48, input wire signed [63:0] x49,
    input wire signed [63:0] x50, input wire signed [63:0] x51,
    input wire signed [63:0] x52, input wire signed [63:0] x53,
    input wire signed [63:0] x54, input wire signed [63:0] x55,
    input wire signed [63:0] x56, input wire signed [63:0] x57,
    input wire signed [63:0] x58, input wire signed [63:0] x59,
    input wire signed [63:0] x60, input wire signed [63:0] x61,
    input wire signed [63:0] x62, input wire signed [63:0] x63,
    input wire signed [63:0] x64, input wire signed [63:0] x65,
    input wire signed [63:0] x66, input wire signed [63:0] x67,
    input wire signed [63:0] x68, input wire signed [63:0] x69,
    input wire signed [63:0] x70, input wire signed [63:0] x71,
    input wire signed [63:0] x72, input wire signed [63:0] x73,
    input wire signed [63:0] x74, input wire signed [63:0] x75,
    input wire signed [63:0] x76, input wire signed [63:0] x77,
    input wire signed [63:0] x78, input wire signed [63:0] x79,
    input wire signed [63:0] x80, input wire signed [63:0] x81,
    input wire signed [63:0] x82, input wire signed [63:0] x83,
    input wire signed [63:0] x84, input wire signed [63:0] x85,
    input wire signed [63:0] x86, input wire signed [63:0] x87,
    input wire signed [63:0] x88, input wire signed [63:0] x89,
    input wire signed [63:0] x90, input wire signed [63:0] x91,
    input wire signed [63:0] x92, input wire signed [63:0] x93,
    input wire signed [63:0] x94, input wire signed [63:0] x95,
    input wire signed [63:0] x96, input wire signed [63:0] x97,
    input wire signed [63:0] x98, input wire signed [63:0] x99,
    input wire signed [63:0] x100,
    output reg signed [63:0] y
);

  reg signed [63:0] x [0:100];
  reg signed [127:0] acc;
  integer i;

  function [31:0] coeff_fp;
    input integer idx;
    begin
      case (idx)
        0: coeff_fp = 32'h39fd56aa;   1: coeff_fp = 32'h39a77386;
        2: coeff_fp = 32'h39334aac;   3: coeff_fp = 32'h386d8991;
        4: coeff_fp = 32'hb5a5aba3;   5: coeff_fp = 32'h37bd8450;
        6: coeff_fp = 32'h391fc780;   7: coeff_fp = 32'h39d475a3;
        8: coeff_fp = 32'h3a4d6269;   9: coeff_fp = 32'h3aa61be3;
        10: coeff_fp = 32'h3aed3bf0; 11: coeff_fp = 32'h3b192db6;
        12: coeff_fp = 32'h3b347633; 13: coeff_fp = 32'h3b418ca6;
        14: coeff_fp = 32'h3b3a03d9; 15: coeff_fp = 32'h3b193e82;
        16: coeff_fp = 32'h3abb6ece; 17: coeff_fp = 32'h391fa206;
        18: coeff_fp = 32'hbab5ebf4; 19: coeff_fp = 32'hbb45facc;
        20: coeff_fp = 32'hbb9488a1; 21: coeff_fp = 32'hbbbaa786;
        22: coeff_fp = 32'hbbceb76a; 23: coeff_fp = 32'hbbcc46b2;
        24: coeff_fp = 32'hbbb25119; 25: coeff_fp = 32'hbb841b84;
        26: coeff_fp = 32'hbb12f16e; 27: coeff_fp = 32'hb9e522de;
        28: coeff_fp = 32'h3a74a930; 29: coeff_fp = 32'h3ab63a39;
        30: coeff_fp = 32'h3a034101; 31: coeff_fp = 32'hbb0600e4;
        32: coeff_fp = 32'hbbd0625a; 33: coeff_fp = 32'hbc49a519;
        34: coeff_fp = 32'hbc9f93b5; 35: coeff_fp = 32'hbcdeddd2;
        36: coeff_fp = 32'hbd0dbce0; 37: coeff_fp = 32'hbd2696ef;
        38: coeff_fp = 32'hbd35d6f1; 39: coeff_fp = 32'hbd37d430;
        40: coeff_fp = 32'hbd29e7d2; 41: coeff_fp = 32'hbd0adcc4;
        42: coeff_fp = 32'hbcb67535; 43: coeff_fp = 32'hbbeaf5be;
        44: coeff_fp = 32'h3c2a8ac6; 45: coeff_fp = 32'h3ceeaa3c;
        46: coeff_fp = 32'h3d42697f; 47: coeff_fp = 32'h3d82ae39;
        48: coeff_fp = 32'h3d9d14a6; 49: coeff_fp = 32'h3dadfa04;
        50: coeff_fp = 32'h3db3ca74; 51: coeff_fp = 32'h3dadfa04;
        52: coeff_fp = 32'h3d9d14a6; 53: coeff_fp = 32'h3d82ae39;
        54: coeff_fp = 32'h3d42697f; 55: coeff_fp = 32'h3ceeaa3c;
        56: coeff_fp = 32'h3c2a8ac6; 57: coeff_fp = 32'hbbeaf5be;
        58: coeff_fp = 32'hbcb67535; 59: coeff_fp = 32'hbd0adcc4;
        60: coeff_fp = 32'hbd29e7d2; 61: coeff_fp = 32'hbd37d430;
        62: coeff_fp = 32'hbd35d6f1; 63: coeff_fp = 32'hbd2696ef;
        64: coeff_fp = 32'hbd0dbce0; 65: coeff_fp = 32'hbcdeddd2;
        66: coeff_fp = 32'hbc9f93b5; 67: coeff_fp = 32'hbc49a519;
        68: coeff_fp = 32'hbbd0625a; 69: coeff_fp = 32'hbb0600e4;
        70: coeff_fp = 32'h3a034101; 71: coeff_fp = 32'h3ab63a39;
        72: coeff_fp = 32'h3a74a930; 73: coeff_fp = 32'hb9e522de;
        74: coeff_fp = 32'hbb12f16e; 75: coeff_fp = 32'hbb841b84;
        76: coeff_fp = 32'hbbb25119; 77: coeff_fp = 32'hbbcc46b2;
        78: coeff_fp = 32'hbbceb76a; 79: coeff_fp = 32'hbbbaa786;
        80: coeff_fp = 32'hbb9488a1; 81: coeff_fp = 32'hbb45facc;
        82: coeff_fp = 32'hbab5ebf4; 83: coeff_fp = 32'h391fa206;
        84: coeff_fp = 32'h3abb6ece; 85: coeff_fp = 32'h3b193e82;
        86: coeff_fp = 32'h3b3a03d9; 87: coeff_fp = 32'h3b418ca6;
        88: coeff_fp = 32'h3b347633; 89: coeff_fp = 32'h3b192db6;
        90: coeff_fp = 32'h3aed3bf0; 91: coeff_fp = 32'h3aa61be3;
        92: coeff_fp = 32'h3a4d6269; 93: coeff_fp = 32'h39d475a3;
        94: coeff_fp = 32'h391fc780; 95: coeff_fp = 32'h37bd8450;
        96: coeff_fp = 32'hb5a5aba3; 97: coeff_fp = 32'h386d8991;
        98: coeff_fp = 32'h39334aac; 99: coeff_fp = 32'h39a77386;
        100: coeff_fp = 32'h39fd56aa;
        default: coeff_fp = 32'h00000000;
      endcase
    end
  endfunction

  function signed [63:0] fp32_to_q32_32;
    input [31:0] fp;
    reg sign;
    reg [7:0] exp;
    reg [23:0] mant;
    reg [127:0] mag;
    integer shift;
    begin
      sign = fp[31];
      exp = fp[30:23];

      if (exp == 8'd0) begin
        mant = {1'b0, fp[22:0]};
        shift = -94;
      end else begin
        mant = {1'b1, fp[22:0]};
        shift = exp - 118;
      end

      if (mant == 24'd0) begin
        fp32_to_q32_32 = 64'sd0;
      end else begin
        if (shift >= 0)
          mag = ({104'd0, mant} << shift);
        else
          mag = ({104'd0, mant} >> -shift);

        fp32_to_q32_32 = sign ? -$signed(mag[63:0]) : $signed(mag[63:0]);
      end
    end
  endfunction

  always @* begin
    x[0] = x0;     x[1] = x1;     x[2] = x2;     x[3] = x3;
    x[4] = x4;     x[5] = x5;     x[6] = x6;     x[7] = x7;
    x[8] = x8;     x[9] = x9;     x[10] = x10;   x[11] = x11;
    x[12] = x12;   x[13] = x13;   x[14] = x14;   x[15] = x15;
    x[16] = x16;   x[17] = x17;   x[18] = x18;   x[19] = x19;
    x[20] = x20;   x[21] = x21;   x[22] = x22;   x[23] = x23;
    x[24] = x24;   x[25] = x25;   x[26] = x26;   x[27] = x27;
    x[28] = x28;   x[29] = x29;   x[30] = x30;   x[31] = x31;
    x[32] = x32;   x[33] = x33;   x[34] = x34;   x[35] = x35;
    x[36] = x36;   x[37] = x37;   x[38] = x38;   x[39] = x39;
    x[40] = x40;   x[41] = x41;   x[42] = x42;   x[43] = x43;
    x[44] = x44;   x[45] = x45;   x[46] = x46;   x[47] = x47;
    x[48] = x48;   x[49] = x49;   x[50] = x50;   x[51] = x51;
    x[52] = x52;   x[53] = x53;   x[54] = x54;   x[55] = x55;
    x[56] = x56;   x[57] = x57;   x[58] = x58;   x[59] = x59;
    x[60] = x60;   x[61] = x61;   x[62] = x62;   x[63] = x63;
    x[64] = x64;   x[65] = x65;   x[66] = x66;   x[67] = x67;
    x[68] = x68;   x[69] = x69;   x[70] = x70;   x[71] = x71;
    x[72] = x72;   x[73] = x73;   x[74] = x74;   x[75] = x75;
    x[76] = x76;   x[77] = x77;   x[78] = x78;   x[79] = x79;
    x[80] = x80;   x[81] = x81;   x[82] = x82;   x[83] = x83;
    x[84] = x84;   x[85] = x85;   x[86] = x86;   x[87] = x87;
    x[88] = x88;   x[89] = x89;   x[90] = x90;   x[91] = x91;
    x[92] = x92;   x[93] = x93;   x[94] = x94;   x[95] = x95;
    x[96] = x96;   x[97] = x97;   x[98] = x98;   x[99] = x99;
    x[100] = x100;

    acc = 128'sd0;
    for (i = 0; i < 101; i = i + 1) begin
      if (i < TAP_CNT)
        acc = acc + (($signed(x[i]) * $signed(fp32_to_q32_32(coeff_fp(i)))) >>> 32);
    end

    y = acc[63:0];
  end

endmodule