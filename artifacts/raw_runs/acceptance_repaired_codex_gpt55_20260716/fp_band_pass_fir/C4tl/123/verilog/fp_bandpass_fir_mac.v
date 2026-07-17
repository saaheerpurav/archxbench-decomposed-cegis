`timescale 1ns/1ps

module fp_bandpass_fir_mac #(
    parameter TAP_CNT = 101
) (
    input  wire [31:0] samples [0:TAP_CNT-1],
    output reg  [31:0] result
);

  function [31:0] coeff_word;
    input integer idx;
    begin
      case (idx)
        0:   coeff_word = 32'h39fd56aa;
        1:   coeff_word = 32'h39a77386;
        2:   coeff_word = 32'h39334aac;
        3:   coeff_word = 32'h386d8991;
        4:   coeff_word = 32'hb5a5aba3;
        5:   coeff_word = 32'h37bd8450;
        6:   coeff_word = 32'h391fc780;
        7:   coeff_word = 32'h39d475a3;
        8:   coeff_word = 32'h3a4d6269;
        9:   coeff_word = 32'h3aa61be3;
        10:  coeff_word = 32'h3aed3bf0;
        11:  coeff_word = 32'h3b192db6;
        12:  coeff_word = 32'h3b347633;
        13:  coeff_word = 32'h3b418ca6;
        14:  coeff_word = 32'h3b3a03d9;
        15:  coeff_word = 32'h3b193e82;
        16:  coeff_word = 32'h3abb6ece;
        17:  coeff_word = 32'h391fa206;
        18:  coeff_word = 32'hbab5ebf4;
        19:  coeff_word = 32'hbb45facc;
        20:  coeff_word = 32'hbb9488a1;
        21:  coeff_word = 32'hbbbaa786;
        22:  coeff_word = 32'hbbceb76a;
        23:  coeff_word = 32'hbbcc46b2;
        24:  coeff_word = 32'hbbb25119;
        25:  coeff_word = 32'hbb841b84;
        26:  coeff_word = 32'hbb12f16e;
        27:  coeff_word = 32'hb9e522de;
        28:  coeff_word = 32'h3a74a930;
        29:  coeff_word = 32'h3ab63a39;
        30:  coeff_word = 32'h3a034101;
        31:  coeff_word = 32'hbb0600e4;
        32:  coeff_word = 32'hbbd0625a;
        33:  coeff_word = 32'hbc49a519;
        34:  coeff_word = 32'hbc9f93b5;
        35:  coeff_word = 32'hbcdeddd2;
        36:  coeff_word = 32'hbd0dbce0;
        37:  coeff_word = 32'hbd2696ef;
        38:  coeff_word = 32'hbd35d6f1;
        39:  coeff_word = 32'hbd37d430;
        40:  coeff_word = 32'hbd29e7d2;
        41:  coeff_word = 32'hbd0adcc4;
        42:  coeff_word = 32'hbcb67535;
        43:  coeff_word = 32'hbbeaf5be;
        44:  coeff_word = 32'h3c2a8ac6;
        45:  coeff_word = 32'h3ceeaa3c;
        46:  coeff_word = 32'h3d42697f;
        47:  coeff_word = 32'h3d82ae39;
        48:  coeff_word = 32'h3d9d14a6;
        49:  coeff_word = 32'h3dadfa04;
        50:  coeff_word = 32'h3db3ca74;
        51:  coeff_word = 32'h3dadfa04;
        52:  coeff_word = 32'h3d9d14a6;
        53:  coeff_word = 32'h3d82ae39;
        54:  coeff_word = 32'h3d42697f;
        55:  coeff_word = 32'h3ceeaa3c;
        56:  coeff_word = 32'h3c2a8ac6;
        57:  coeff_word = 32'hbbeaf5be;
        58:  coeff_word = 32'hbcb67535;
        59:  coeff_word = 32'hbd0adcc4;
        60:  coeff_word = 32'hbd29e7d2;
        61:  coeff_word = 32'hbd37d430;
        62:  coeff_word = 32'hbd35d6f1;
        63:  coeff_word = 32'hbd2696ef;
        64:  coeff_word = 32'hbd0dbce0;
        65:  coeff_word = 32'hbcdeddd2;
        66:  coeff_word = 32'hbc9f93b5;
        67:  coeff_word = 32'hbc49a519;
        68:  coeff_word = 32'hbbd0625a;
        69:  coeff_word = 32'hbb0600e4;
        70:  coeff_word = 32'h3a034101;
        71:  coeff_word = 32'h3ab63a39;
        72:  coeff_word = 32'h3a74a930;
        73:  coeff_word = 32'hb9e522de;
        74:  coeff_word = 32'hbb12f16e;
        75:  coeff_word = 32'hbb841b84;
        76:  coeff_word = 32'hbbb25119;
        77:  coeff_word = 32'hbbcc46b2;
        78:  coeff_word = 32'hbbceb76a;
        79:  coeff_word = 32'hbbbaa786;
        80:  coeff_word = 32'hbb9488a1;
        81:  coeff_word = 32'hbb45facc;
        82:  coeff_word = 32'hbab5ebf4;
        83:  coeff_word = 32'h391fa206;
        84:  coeff_word = 32'h3abb6ece;
        85:  coeff_word = 32'h3b193e82;
        86:  coeff_word = 32'h3b3a03d9;
        87:  coeff_word = 32'h3b418ca6;
        88:  coeff_word = 32'h3b347633;
        89:  coeff_word = 32'h3b192db6;
        90:  coeff_word = 32'h3aed3bf0;
        91:  coeff_word = 32'h3aa61be3;
        92:  coeff_word = 32'h3a4d6269;
        93:  coeff_word = 32'h39d475a3;
        94:  coeff_word = 32'h391fc780;
        95:  coeff_word = 32'h37bd8450;
        96:  coeff_word = 32'hb5a5aba3;
        97:  coeff_word = 32'h386d8991;
        98:  coeff_word = 32'h39334aac;
        99:  coeff_word = 32'h39a77386;
        100: coeff_word = 32'h39fd56aa;
        default: coeff_word = 32'h00000000;
      endcase
    end
  endfunction

  integer k;
  shortreal acc;
  shortreal sample_r;
  shortreal coeff_r;
  shortreal prod;

  always @* begin
    acc = 0.0;

    for (k = 0; k < TAP_CNT; k = k + 1) begin
      sample_r = $bitstoshortreal(samples[k]);
      coeff_r = $bitstoshortreal(coeff_word(k));
      prod = sample_r * coeff_r;
      acc = acc + prod;
    end

    result = $shortrealtobits(acc);
  end

endmodule