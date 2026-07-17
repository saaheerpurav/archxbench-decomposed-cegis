`timescale 1ns/1ps

module fp_highpass_coeff_rom #(
    parameter INDEX = 0
) (
    output reg [31:0] coeff
);

  always @* begin
    case (INDEX)
      0:   coeff = 32'h21a5e407;
      1:   coeff = 32'h39a1fef1;
      2:   coeff = 32'h3a0a48e5;
      3:   coeff = 32'h3a14dc7c;
      4:   coeff = 32'h39c9729c;
      5:   coeff = 32'h21373cac;
      6:   coeff = 32'hb9fa686f;
      7:   coeff = 32'hba647ae3;
      8:   coeff = 32'hba815b49;
      9:   coeff = 32'hba3564bc;
      10:  coeff = 32'ha2c126e6;
      11:  coeff = 32'h3a696787;
      12:  coeff = 32'h3ad5c178;
      13:  coeff = 32'h3af17343;
      14:  coeff = 32'h3aa82360;
      15:  coeff = 32'h239ded49;
      16:  coeff = 32'hbad3be22;
      17:  coeff = 32'hbb3f7379;
      18:  coeff = 32'hbb556676;
      19:  coeff = 32'hbb12a289;
      20:  coeff = 32'ha4439339;
      21:  coeff = 32'h3b33fb1e;
      22:  coeff = 32'h3ba0cd0c;
      23:  coeff = 32'h3bb13ea7;
      24:  coeff = 32'h3b71153f;
      25:  coeff = 32'ha30bf866;
      26:  coeff = 32'hbb915883;
      27:  coeff = 32'hbc00e7a5;
      28:  coeff = 32'hbc0d333a;
      29:  coeff = 32'hbbbf1429;
      30:  coeff = 32'ha3c43dcb;
      31:  coeff = 32'h3be4ec47;
      32:  coeff = 32'h3c4accff;
      33:  coeff = 32'h3c5e3e69;
      34:  coeff = 32'h3c16b483;
      35:  coeff = 32'h24c72eb7;
      36:  coeff = 32'hbc367814;
      37:  coeff = 32'hbca31ca3;
      38:  coeff = 32'hbcb4ed9c;
      39:  coeff = 32'hbc794bfe;
      40:  coeff = 32'ha403343e;
      41:  coeff = 32'h3c9e21ad;
      42:  coeff = 32'h3d1233f3;
      43:  coeff = 32'h3d2969d5;
      44:  coeff = 32'h3cf73d64;
      45:  coeff = 32'h240c9a35;
      46:  coeff = 32'hbd3cd9b8;
      47:  coeff = 32'hbdcd0395;
      48:  coeff = 32'hbe1a7617;
      49:  coeff = 32'hbe3f721e;
      50:  coeff = 32'h3f4cd56c;
      51:  coeff = 32'hbe3f721e;
      52:  coeff = 32'hbe1a7617;
      53:  coeff = 32'hbdcd0395;
      54:  coeff = 32'hbd3cd9b8;
      55:  coeff = 32'h240c9a35;
      56:  coeff = 32'h3cf73d64;
      57:  coeff = 32'h3d2969d5;
      58:  coeff = 32'h3d1233f3;
      59:  coeff = 32'h3c9e21ad;
      60:  coeff = 32'ha403343e;
      61:  coeff = 32'hbc794bfe;
      62:  coeff = 32'hbcb4ed9c;
      63:  coeff = 32'hbca31ca3;
      64:  coeff = 32'hbc367814;
      65:  coeff = 32'h24c72eb7;
      66:  coeff = 32'h3c16b483;
      67:  coeff = 32'h3c5e3e69;
      68:  coeff = 32'h3c4accff;
      69:  coeff = 32'h3be4ec47;
      70:  coeff = 32'ha3c43dcb;
      71:  coeff = 32'hbbbf1429;
      72:  coeff = 32'hbc0d333a;
      73:  coeff = 32'hbc00e7a5;
      74:  coeff = 32'hbb915883;
      75:  coeff = 32'ha30bf866;
      76:  coeff = 32'h3b71153f;
      77:  coeff = 32'h3bb13ea7;
      78:  coeff = 32'h3ba0cd0c;
      79:  coeff = 32'h3b33fb1e;
      80:  coeff = 32'ha4439339;
      81:  coeff = 32'hbb12a289;
      82:  coeff = 32'hbb556676;
      83:  coeff = 32'hbb3f7379;
      84:  coeff = 32'hbad3be22;
      85:  coeff = 32'h239ded49;
      86:  coeff = 32'h3aa82360;
      87:  coeff = 32'h3af17343;
      88:  coeff = 32'h3ad5c178;
      89:  coeff = 32'h3a696787;
      90:  coeff = 32'ha2c126e6;
      91:  coeff = 32'hba3564bc;
      92:  coeff = 32'hba815b49;
      93:  coeff = 32'hba647ae3;
      94:  coeff = 32'hb9fa686f;
      95:  coeff = 32'h21373cac;
      96:  coeff = 32'h39c9729c;
      97:  coeff = 32'h3a14dc7c;
      98:  coeff = 32'h3a0a48e5;
      99:  coeff = 32'h39a1fef1;
      100: coeff = 32'h21a5e407;
      default: coeff = 32'h00000000;
    endcase
  end

endmodule