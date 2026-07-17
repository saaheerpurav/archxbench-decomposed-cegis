`timescale 1ns/1ps

module fp_fir_mac_101 #(
    parameter TAP_CNT = 101
) (
    input  wire [TAP_CNT*32-1:0] samples,
    output reg  [31:0] result
);

  integer i;
  reg [31:0] coeff_word;
  real acc;

  function real pow2_real;
    input integer e;
    integer k;
    real v;
    begin
      v = 1.0;
      if (e >= 0) begin
        for (k = 0; k < e; k = k + 1)
          v = v * 2.0;
      end else begin
        for (k = 0; k < -e; k = k + 1)
          v = v / 2.0;
      end
      pow2_real = v;
    end
  endfunction

  function real fp32_to_real;
    input [31:0] x;
    integer exp_bits;
    integer mant_bits;
    real val;
    begin
      exp_bits = x[30:23];
      mant_bits = x[22:0];

      if (exp_bits == 0 && mant_bits == 0) begin
        val = 0.0;
      end else if (exp_bits == 0) begin
        val = mant_bits;
        val = val / 8388608.0;
        val = val * pow2_real(-126);
      end else begin
        val = 1.0 + (mant_bits / 8388608.0);
        val = val * pow2_real(exp_bits - 127);
      end

      if (x[31])
        fp32_to_real = -val;
      else
        fp32_to_real = val;
    end
  endfunction

  function [31:0] real_to_fp32;
    input real r;
    reg sign;
    real a;
    real norm;
    real frac_scaled;
    integer exp_unbiased;
    integer exp_bits;
    integer mant;
    begin
      if (r == 0.0) begin
        real_to_fp32 = 32'h00000000;
      end else begin
        sign = (r < 0.0);
        a = sign ? -r : r;

        exp_unbiased = 0;
        norm = a;

        while (norm >= 2.0) begin
          norm = norm / 2.0;
          exp_unbiased = exp_unbiased + 1;
        end

        while (norm < 1.0) begin
          norm = norm * 2.0;
          exp_unbiased = exp_unbiased - 1;
        end

        exp_bits = exp_unbiased + 127;

        if (exp_bits <= 0) begin
          real_to_fp32 = {sign, 31'h00000000};
        end else if (exp_bits >= 255) begin
          real_to_fp32 = {sign, 8'hfe, 23'h7fffff};
        end else begin
          frac_scaled = (norm - 1.0) * 8388608.0;
          mant = frac_scaled + 0.5;

          if (mant >= 8388608) begin
            mant = 0;
            exp_bits = exp_bits + 1;
          end

          if (exp_bits >= 255)
            real_to_fp32 = {sign, 8'hfe, 23'h7fffff};
          else
            real_to_fp32 = {sign, exp_bits[7:0], mant[22:0]};
        end
      end
    end
  endfunction

  task get_coeff;
    input integer idx;
    output [31:0] coeff;
    begin
      case (idx)
        0: coeff = 32'h39fd56aa;
        1: coeff = 32'h39a77386;
        2: coeff = 32'h39334aac;
        3: coeff = 32'h386d8991;
        4: coeff = 32'hb5a5aba3;
        5: coeff = 32'h37bd8450;
        6: coeff = 32'h391fc780;
        7: coeff = 32'h39d475a3;
        8: coeff = 32'h3a4d6269;
        9: coeff = 32'h3aa61be3;
        10: coeff = 32'h3aed3bf0;
        11: coeff = 32'h3b192db6;
        12: coeff = 32'h3b347633;
        13: coeff = 32'h3b418ca6;
        14: coeff = 32'h3b3a03d9;
        15: coeff = 32'h3b193e82;
        16: coeff = 32'h3abb6ece;
        17: coeff = 32'h391fa206;
        18: coeff = 32'hbab5ebf4;
        19: coeff = 32'hbb45facc;
        20: coeff = 32'hbb9488a1;
        21: coeff = 32'hbbbaa786;
        22: coeff = 32'hbbceb76a;
        23: coeff = 32'hbbcc46b2;
        24: coeff = 32'hbbb25119;
        25: coeff = 32'hbb841b84;
        26: coeff = 32'hbb12f16e;
        27: coeff = 32'hb9e522de;
        28: coeff = 32'h3a74a930;
        29: coeff = 32'h3ab63a39;
        30: coeff = 32'h3a034101;
        31: coeff = 32'hbb0600e4;
        32: coeff = 32'hbbd0625a;
        33: coeff = 32'hbc49a519;
        34: coeff = 32'hbc9f93b5;
        35: coeff = 32'hbcdeddd2;
        36: coeff = 32'hbd0dbce0;
        37: coeff = 32'hbd2696ef;
        38: coeff = 32'hbd35d6f1;
        39: coeff = 32'hbd37d430;
        40: coeff = 32'hbd29e7d2;
        41: coeff = 32'hbd0adcc4;
        42: coeff = 32'hbcb67535;
        43: coeff = 32'hbbeaf5be;
        44: coeff = 32'h3c2a8ac6;
        45: coeff = 32'h3ceeaa3c;
        46: coeff = 32'h3d42697f;
        47: coeff = 32'h3d82ae39;
        48: coeff = 32'h3d9d14a6;
        49: coeff = 32'h3dadfa04;
        50: coeff = 32'h3db3ca74;
        51: coeff = 32'h3dadfa04;
        52: coeff = 32'h3d9d14a6;
        53: coeff = 32'h3d82ae39;
        54: coeff = 32'h3d42697f;
        55: coeff = 32'h3ceeaa3c;
        56: coeff = 32'h3c2a8ac6;
        57: coeff = 32'hbbeaf5be;
        58: coeff = 32'hbcb67535;
        59: coeff = 32'hbd0adcc4;
        60: coeff = 32'hbd29e7d2;
        61: coeff = 32'hbd37d430;
        62: coeff = 32'hbd35d6f1;
        63: coeff = 32'hbd2696ef;
        64: coeff = 32'hbd0dbce0;
        65: coeff = 32'hbcdeddd2;
        66: coeff = 32'hbc9f93b5;
        67: coeff = 32'hbc49a519;
        68: coeff = 32'hbbd0625a;
        69: coeff = 32'hbb0600e4;
        70: coeff = 32'h3a034101;
        71: coeff = 32'h3ab63a39;
        72: coeff = 32'h3a74a930;
        73: coeff = 32'hb9e522de;
        74: coeff = 32'hbb12f16e;
        75: coeff = 32'hbb841b84;
        76: coeff = 32'hbbb25119;
        77: coeff = 32'hbbcc46b2;
        78: coeff = 32'hbbceb76a;
        79: coeff = 32'hbbbaa786;
        80: coeff = 32'hbb9488a1;
        81: coeff = 32'hbb45facc;
        82: coeff = 32'hbab5ebf4;
        83: coeff = 32'h391fa206;
        84: coeff = 32'h3abb6ece;
        85: coeff = 32'h3b193e82;
        86: coeff = 32'h3b3a03d9;
        87: coeff = 32'h3b418ca6;
        88: coeff = 32'h3b347633;
        89: coeff = 32'h3b192db6;
        90: coeff = 32'h3aed3bf0;
        91: coeff = 32'h3aa61be3;
        92: coeff = 32'h3a4d6269;
        93: coeff = 32'h39d475a3;
        94: coeff = 32'h391fc780;
        95: coeff = 32'h37bd8450;
        96: coeff = 32'hb5a5aba3;
        97: coeff = 32'h386d8991;
        98: coeff = 32'h39334aac;
        99: coeff = 32'h39a77386;
        100: coeff = 32'h39fd56aa;
        default: coeff = 32'h00000000;
      endcase
    end
  endtask

  always @* begin
    acc = 0.0;

    for (i = 0; i < TAP_CNT; i = i + 1) begin
      get_coeff(i, coeff_word);
      acc = acc + fp32_to_real(samples[i*32 +: 32]) * fp32_to_real(coeff_word);
    end

    result = real_to_fp32(acc);
  end

endmodule