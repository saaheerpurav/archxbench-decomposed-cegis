`timescale 1ns/1ps

module fp_fir_mac_comb #(
    parameter TAP_CNT = 101
) (
    input wire [32*TAP_CNT-1:0] samples,
    output wire [31:0] result
);

  integer k;
  reg [31:0] acc;
  wire [31:0] prod;
  reg [31:0] x_sel;
  reg [31:0] h_sel;

  fp32_mul_comb u_mul (.a(x_sel), .b(h_sel), .y(prod));

  function [31:0] coeff;
    input integer idx;
    begin
      case (idx)
        0: coeff = 32'h39fd56aa; 1: coeff = 32'h39a77386; 2: coeff = 32'h39334aac;
        3: coeff = 32'h386d8991; 4: coeff = 32'hb5a5aba3; 5: coeff = 32'h37bd8450;
        6: coeff = 32'h391fc780; 7: coeff = 32'h39d475a3; 8: coeff = 32'h3a4d6269;
        9: coeff = 32'h3aa61be3; 10: coeff = 32'h3aed3bf0; 11: coeff = 32'h3b192db6;
        12: coeff = 32'h3b347633; 13: coeff = 32'h3b418ca6; 14: coeff = 32'h3b3a03d9;
        15: coeff = 32'h3b193e82; 16: coeff = 32'h3abb6ece; 17: coeff = 32'h391fa206;
        18: coeff = 32'hbab5ebf4; 19: coeff = 32'hbb45facc; 20: coeff = 32'hbb9488a1;
        21: coeff = 32'hbbbaa786; 22: coeff = 32'hbbceb76a; 23: coeff = 32'hbbcc46b2;
        24: coeff = 32'hbbb25119; 25: coeff = 32'hbb841b84; 26: coeff = 32'hbb12f16e;
        27: coeff = 32'hb9e522de; 28: coeff = 32'h3a74a930; 29: coeff = 32'h3ab63a39;
        30: coeff = 32'h3a034101; 31: coeff = 32'hbb0600e4; 32: coeff = 32'hbbd0625a;
        33: coeff = 32'hbc49a519; 34: coeff = 32'hbc9f93b5; 35: coeff = 32'hbcdeddd2;
        36: coeff = 32'hbd0dbce0; 37: coeff = 32'hbd2696ef; 38: coeff = 32'hbd35d6f1;
        39: coeff = 32'hbd37d430; 40: coeff = 32'hbd29e7d2; 41: coeff = 32'hbd0adcc4;
        42: coeff = 32'hbcb67535; 43: coeff = 32'hbbeaf5be; 44: coeff = 32'h3c2a8ac6;
        45: coeff = 32'h3ceeaa3c; 46: coeff = 32'h3d42697f; 47: coeff = 32'h3d82ae39;
        48: coeff = 32'h3d9d14a6; 49: coeff = 32'h3dadfa04; 50: coeff = 32'h3db3ca74;
        51: coeff = 32'h3dadfa04; 52: coeff = 32'h3d9d14a6; 53: coeff = 32'h3d82ae39;
        54: coeff = 32'h3d42697f; 55: coeff = 32'h3ceeaa3c; 56: coeff = 32'h3c2a8ac6;
        57: coeff = 32'hbbeaf5be; 58: coeff = 32'hbcb67535; 59: coeff = 32'hbd0adcc4;
        60: coeff = 32'hbd29e7d2; 61: coeff = 32'hbd37d430; 62: coeff = 32'hbd35d6f1;
        63: coeff = 32'hbd2696ef; 64: coeff = 32'hbd0dbce0; 65: coeff = 32'hbcdeddd2;
        66: coeff = 32'hbc9f93b5; 67: coeff = 32'hbc49a519; 68: coeff = 32'hbbd0625a;
        69: coeff = 32'hbb0600e4; 70: coeff = 32'h3a034101; 71: coeff = 32'h3ab63a39;
        72: coeff = 32'h3a74a930; 73: coeff = 32'hb9e522de; 74: coeff = 32'hbb12f16e;
        75: coeff = 32'hbb841b84; 76: coeff = 32'hbbb25119; 77: coeff = 32'hbbcc46b2;
        78: coeff = 32'hbbceb76a; 79: coeff = 32'hbbbaa786; 80: coeff = 32'hbb9488a1;
        81: coeff = 32'hbb45facc; 82: coeff = 32'hbab5ebf4; 83: coeff = 32'h391fa206;
        84: coeff = 32'h3abb6ece; 85: coeff = 32'h3b193e82; 86: coeff = 32'h3b3a03d9;
        87: coeff = 32'h3b418ca6; 88: coeff = 32'h3b347633; 89: coeff = 32'h3b192db6;
        90: coeff = 32'h3aed3bf0; 91: coeff = 32'h3aa61be3; 92: coeff = 32'h3a4d6269;
        93: coeff = 32'h39d475a3; 94: coeff = 32'h391fc780; 95: coeff = 32'h37bd8450;
        96: coeff = 32'hb5a5aba3; 97: coeff = 32'h386d8991; 98: coeff = 32'h39334aac;
        99: coeff = 32'h39a77386; 100: coeff = 32'h39fd56aa;
        default: coeff = 32'h00000000;
      endcase
    end
  endfunction

  function [31:0] fp_add_local;
    input [31:0] a, b;
    real ar, br, rr;
    begin
      ar = fp32_to_real(a);
      br = fp32_to_real(b);
      rr = ar + br;
      fp_add_local = real_to_fp32(rr);
    end
  endfunction

  function real fp32_to_real;
    input [31:0] f;
    integer exp;
    integer mant;
    real m;
    begin
      if (f[30:23] == 8'd0 && f[22:0] == 23'd0)
        fp32_to_real = 0.0;
      else begin
        exp = f[30:23] - 127;
        mant = f[22:0];
        m = (f[30:23] == 8'd0) ? (mant / 8388608.0) : (1.0 + mant / 8388608.0);
        fp32_to_real = f[31] ? -m * pow2(exp) : m * pow2(exp);
      end
    end
  endfunction

  function real pow2;
    input integer e;
    integer j;
    real v;
    begin
      v = 1.0;
      if (e >= 0)
        for (j = 0; j < e; j = j + 1) v = v * 2.0;
      else
        for (j = 0; j < -e; j = j + 1) v = v / 2.0;
      pow2 = v;
    end
  endfunction

  function [31:0] real_to_fp32;
    input real r;
    reg sign;
    real v, scaled, frac;
    integer exp, mant;
    begin
      if (r == 0.0) begin
        real_to_fp32 = 32'h00000000;
      end else begin
        sign = (r < 0.0);
        v = sign ? -r : r;
        exp = 0;
        while (v >= 2.0) begin v = v / 2.0; exp = exp + 1; end
        while (v < 1.0) begin v = v * 2.0; exp = exp - 1; end
        scaled = (v - 1.0) * 8388608.0;
        mant = scaled + 0.5;
        if (mant >= 8388608) begin mant = 0; exp = exp + 1; end
        if (exp + 127 <= 0)
          real_to_fp32 = 32'h00000000;
        else if (exp + 127 >= 255)
          real_to_fp32 = {sign, 8'hfe, 23'h7fffff};
        else
          real_to_fp32 = {sign, exp[7:0] + 8'd127, mant[22:0]};
      end
    end
  endfunction

  always @* begin
    acc = 32'h00000000;
    x_sel = 32'h00000000;
    h_sel = 32'h00000000;
    for (k = 0; k < TAP_CNT; k = k + 1) begin
      x_sel = samples[k*32 +: 32];
      h_sel = coeff(k);
      #0 acc = fp_add_local(acc, prod);
    end
  end

  assign result = acc;

endmodule