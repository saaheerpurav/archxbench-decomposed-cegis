`timescale 1ns/1ps

module fp_hpf_coeff_rom #(
    parameter TAP_CNT = 101
) (
    output wire [32*TAP_CNT-1:0] coeff_bus
);

  function [31:0] coeff_at;
    input integer idx;
    begin
      case (idx)
        0:   coeff_at = 32'h21a5e407;
        1:   coeff_at = 32'h39a1fef1;
        2:   coeff_at = 32'h3a0a48e5;
        3:   coeff_at = 32'h3a14dc7c;
        4:   coeff_at = 32'h39c9729c;
        5:   coeff_at = 32'h21373cac;
        6:   coeff_at = 32'hb9fa686f;
        7:   coeff_at = 32'hba647ae3;
        8:   coeff_at = 32'hba815b49;
        9:   coeff_at = 32'hba3564bc;
        10:  coeff_at = 32'ha2c126e6;
        11:  coeff_at = 32'h3a696787;
        12:  coeff_at = 32'h3ad5c178;
        13:  coeff_at = 32'h3af17343;
        14:  coeff_at = 32'h3aa82360;
        15:  coeff_at = 32'h239ded49;
        16:  coeff_at = 32'hbad3be22;
        17:  coeff_at = 32'hbb3f7379;
        18:  coeff_at = 32'hbb556676;
        19:  coeff_at = 32'hbb12a289;
        20:  coeff_at = 32'ha4439339;
        21:  coeff_at = 32'h3b33fb1e;
        22:  coeff_at = 32'h3ba0cd0c;
        23:  coeff_at = 32'h3bb13ea7;
        24:  coeff_at = 32'h3b71153f;
        25:  coeff_at = 32'ha30bf866;
        26:  coeff_at = 32'hbb915883;
        27:  coeff_at = 32'hbc00e7a5;
        28:  coeff_at = 32'hbc0d333a;
        29:  coeff_at = 32'hbbbf1429;
        30:  coeff_at = 32'ha3c43dcb;
        31:  coeff_at = 32'h3be4ec47;
        32:  coeff_at = 32'h3c4accff;
        33:  coeff_at = 32'h3c5e3e69;
        34:  coeff_at = 32'h3c16b483;
        35:  coeff_at = 32'h24c72eb7;
        36:  coeff_at = 32'hbc367814;
        37:  coeff_at = 32'hbca31ca3;
        38:  coeff_at = 32'hbcb4ed9c;
        39:  coeff_at = 32'hbc794bfe;
        40:  coeff_at = 32'ha403343e;
        41:  coeff_at = 32'h3c9e21ad;
        42:  coeff_at = 32'h3d1233f3;
        43:  coeff_at = 32'h3d2969d5;
        44:  coeff_at = 32'h3cf73d64;
        45:  coeff_at = 32'h240c9a35;
        46:  coeff_at = 32'hbd3cd9b8;
        47:  coeff_at = 32'hbdcd0395;
        48:  coeff_at = 32'hbe1a7617;
        49:  coeff_at = 32'hbe3f721e;
        50:  coeff_at = 32'h3f4cd56c;
        51:  coeff_at = 32'hbe3f721e;
        52:  coeff_at = 32'hbe1a7617;
        53:  coeff_at = 32'hbdcd0395;
        54:  coeff_at = 32'hbd3cd9b8;
        55:  coeff_at = 32'h240c9a35;
        56:  coeff_at = 32'h3cf73d64;
        57:  coeff_at = 32'h3d2969d5;
        58:  coeff_at = 32'h3d1233f3;
        59:  coeff_at = 32'h3c9e21ad;
        60:  coeff_at = 32'ha403343e;
        61:  coeff_at = 32'hbc794bfe;
        62:  coeff_at = 32'hbcb4ed9c;
        63:  coeff_at = 32'hbca31ca3;
        64:  coeff_at = 32'hbc367814;
        65:  coeff_at = 32'h24c72eb7;
        66:  coeff_at = 32'h3c16b483;
        67:  coeff_at = 32'h3c5e3e69;
        68:  coeff_at = 32'h3c4accff;
        69:  coeff_at = 32'h3be4ec47;
        70:  coeff_at = 32'ha3c43dcb;
        71:  coeff_at = 32'hbbbf1429;
        72:  coeff_at = 32'hbc0d333a;
        73:  coeff_at = 32'hbc00e7a5;
        74:  coeff_at = 32'hbb915883;
        75:  coeff_at = 32'ha30bf866;
        76:  coeff_at = 32'h3b71153f;
        77:  coeff_at = 32'h3bb13ea7;
        78:  coeff_at = 32'h3ba0cd0c;
        79:  coeff_at = 32'h3b33fb1e;
        80:  coeff_at = 32'ha4439339;
        81:  coeff_at = 32'hbb12a289;
        82:  coeff_at = 32'hbb556676;
        83:  coeff_at = 32'hbb3f7379;
        84:  coeff_at = 32'hbad3be22;
        85:  coeff_at = 32'h239ded49;
        86:  coeff_at = 32'h3aa82360;
        87:  coeff_at = 32'h3af17343;
        88:  coeff_at = 32'h3ad5c178;
        89:  coeff_at = 32'h3a696787;
        90:  coeff_at = 32'ha2c126e6;
        91:  coeff_at = 32'hba3564bc;
        92:  coeff_at = 32'hba815b49;
        93:  coeff_at = 32'hba647ae3;
        94:  coeff_at = 32'hb9fa686f;
        95:  coeff_at = 32'h21373cac;
        96:  coeff_at = 32'h39c9729c;
        97:  coeff_at = 32'h3a14dc7c;
        98:  coeff_at = 32'h3a0a48e5;
        99:  coeff_at = 32'h39a1fef1;
        100: coeff_at = 32'h21a5e407;
        default: coeff_at = 32'h00000000;
      endcase
    end
  endfunction

  genvar i;
  generate
    for (i = 0; i < TAP_CNT; i = i + 1) begin : GEN_COEFF_BUS
      assign coeff_bus[32*i +: 32] = coeff_at(i);
    end
  endgenerate

endmodule