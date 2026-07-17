`timescale 1ns/1ps

module hp_fir_mac_comb #(
    parameter TAP_CNT = 101
) (
    input wire [TAP_CNT*32-1:0] samples_flat,
    output wire [31:0] result
);

  integer i;
  real acc;
  real sx;
  real hc;
  reg [31:0] result_reg;

  assign result = result_reg;

  function real fp32_to_real;
    input [31:0] bits;
    integer exp;
    integer frac;
    real mant;
    real val;
    begin
      exp = bits[30:23];
      frac = bits[22:0];
      if (exp == 0 && frac == 0) begin
        val = 0.0;
      end else if (exp == 0) begin
        mant = frac / 8388608.0;
        val = mant * pow2_real(-126);
      end else begin
        mant = 1.0 + (frac / 8388608.0);
        val = mant * pow2_real(exp - 127);
      end
      if (bits[31])
        val = -val;
      fp32_to_real = val;
    end
  endfunction

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
          v = v * 0.5;
      end
      pow2_real = v;
    end
  endfunction

  function [31:0] real_to_fp32;
    input real x;
    reg sign;
    real ax;
    real norm;
    real frac_real;
    integer exp;
    integer exp_bits;
    integer frac_bits;
    begin
      if (x == 0.0) begin
        real_to_fp32 = 32'h00000000;
      end else begin
        sign = (x < 0.0);
        ax = sign ? -x : x;
        exp = 0;
        norm = ax;

        while (norm >= 2.0) begin
          norm = norm * 0.5;
          exp = exp + 1;
        end
        while (norm < 1.0) begin
          norm = norm * 2.0;
          exp = exp - 1;
        end

        exp_bits = exp + 127;
        if (exp_bits >= 255) begin
          real_to_fp32 = {sign, 8'hfe, 23'h7fffff};
        end else if (exp_bits <= 0) begin
          real_to_fp32 = {sign, 31'h00000000};
        end else begin
          frac_real = (norm - 1.0) * 8388608.0;
          frac_bits = $rtoi(frac_real + 0.5);
          if (frac_bits >= 8388608) begin
            frac_bits = 0;
            exp_bits = exp_bits + 1;
            if (exp_bits >= 255)
              exp_bits = 254;
          end
          real_to_fp32 = {sign, exp_bits[7:0], frac_bits[22:0]};
        end
      end
    end
  endfunction

  function [31:0] coeff_word;
    input integer idx;
    begin
      case (idx)
        0: coeff_word = 32'h21a5e407;
        1: coeff_word = 32'h39a1fef1;
        2: coeff_word = 32'h3a0a48e5;
        3: coeff_word = 32'h3a14dc7c;
        4: coeff_word = 32'h39c9729c;
        5: coeff_word = 32'h21373cac;
        6: coeff_word = 32'hb9fa686f;
        7: coeff_word = 32'hba647ae3;
        8: coeff_word = 32'hba815b49;
        9: coeff_word = 32'hba3564bc;
        10: coeff_word = 32'ha2c126e6;
        11: coeff_word = 32'h3a696787;
        12: coeff_word = 32'h3ad5c178;
        13: coeff_word = 32'h3af17343;
        14: coeff_word = 32'h3aa82360;
        15: coeff_word = 32'h239ded49;
        16: coeff_word = 32'hbad3be22;
        17: coeff_word = 32'hbb3f7379;
        18: coeff_word = 32'hbb556676;
        19: coeff_word = 32'hbb12a289;
        20: coeff_word = 32'ha4439339;
        21: coeff_word = 32'h3b33fb1e;
        22: coeff_word = 32'h3ba0cd0c;
        23: coeff_word = 32'h3bb13ea7;
        24: coeff_word = 32'h3b71153f;
        25: coeff_word = 32'ha30bf866;
        26: coeff_word = 32'hbb915883;
        27: coeff_word = 32'hbc00e7a5;
        28: coeff_word = 32'hbc0d333a;
        29: coeff_word = 32'hbbbf1429;
        30: coeff_word = 32'ha3c43dcb;
        31: coeff_word = 32'h3be4ec47;
        32: coeff_word = 32'h3c4accff;
        33: coeff_word = 32'h3c5e3e69;
        34: coeff_word = 32'h3c16b483;
        35: coeff_word = 32'h24c72eb7;
        36: coeff_word = 32'hbc367814;
        37: coeff_word = 32'hbca31ca3;
        38: coeff_word = 32'hbcb4ed9c;
        39: coeff_word = 32'hbc794bfe;
        40: coeff_word = 32'ha403343e;
        41: coeff_word = 32'h3c9e21ad;
        42: coeff_word = 32'h3d1233f3;
        43: coeff_word = 32'h3d2969d5;
        44: coeff_word = 32'h3cf73d64;
        45: coeff_word = 32'h240c9a35;
        46: coeff_word = 32'hbd3cd9b8;
        47: coeff_word = 32'hbdcd0395;
        48: coeff_word = 32'hbe1a7617;
        49: coeff_word = 32'hbe3f721e;
        50: coeff_word = 32'h3f4cd56c;
        51: coeff_word = 32'hbe3f721e;
        52: coeff_word = 32'hbe1a7617;
        53: coeff_word = 32'hbdcd0395;
        54: coeff_word = 32'hbd3cd9b8;
        55: coeff_word = 32'h240c9a35;
        56: coeff_word = 32'h3cf73d64;
        57: coeff_word = 32'h3d2969d5;
        58: coeff_word = 32'h3d1233f3;
        59: coeff_word = 32'h3c9e21ad;
        60: coeff_word = 32'ha403343e;
        61: coeff_word = 32'hbc794bfe;
        62: coeff_word = 32'hbcb4ed9c;
        63: coeff_word = 32'hbca31ca3;
        64: coeff_word = 32'hbc367814;
        65: coeff_word = 32'h24c72eb7;
        66: coeff_word = 32'h3c16b483;
        67: coeff_word = 32'h3c5e3e69;
        68: coeff_word = 32'h3c4accff;
        69: coeff_word = 32'h3be4ec47;
        70: coeff_word = 32'ha3c43dcb;
        71: coeff_word = 32'hbbbf1429;
        72: coeff_word = 32'hbc0d333a;
        73: coeff_word = 32'hbc00e7a5;
        74: coeff_word = 32'hbb915883;
        75: coeff_word = 32'ha30bf866;
        76: coeff_word = 32'h3b71153f;
        77: coeff_word = 32'h3bb13ea7;
        78: coeff_word = 32'h3ba0cd0c;
        79: coeff_word = 32'h3b33fb1e;
        80: coeff_word = 32'ha4439339;
        81: coeff_word = 32'hbb12a289;
        82: coeff_word = 32'hbb556676;
        83: coeff_word = 32'hbb3f7379;
        84: coeff_word = 32'hbad3be22;
        85: coeff_word = 32'h239ded49;
        86: coeff_word = 32'h3aa82360;
        87: coeff_word = 32'h3af17343;
        88: coeff_word = 32'h3ad5c178;
        89: coeff_word = 32'h3a696787;
        90: coeff_word = 32'ha2c126e6;
        91: coeff_word = 32'hba3564bc;
        92: coeff_word = 32'hba815b49;
        93: coeff_word = 32'hba647ae3;
        94: coeff_word = 32'hb9fa686f;
        95: coeff_word = 32'h21373cac;
        96: coeff_word = 32'h39c9729c;
        97: coeff_word = 32'h3a14dc7c;
        98: coeff_word = 32'h3a0a48e5;
        99: coeff_word = 32'h39a1fef1;
        100: coeff_word = 32'h21a5e407;
        default: coeff_word = 32'h00000000;
      endcase
    end
  endfunction

  always @* begin
    acc = 0.0;
    for (i = 0; i < TAP_CNT; i = i + 1) begin
      sx = fp32_to_real(samples_flat[i*32 +: 32]);
      hc = fp32_to_real(coeff_word(i));
      acc = acc + (sx * hc);
    end
    result_reg = real_to_fp32(acc);
  end

endmodule