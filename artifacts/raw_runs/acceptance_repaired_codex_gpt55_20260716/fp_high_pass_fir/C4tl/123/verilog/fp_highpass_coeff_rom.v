`timescale 1ns/1ps

module fp_highpass_coeff_rom #(
    parameter TAP_CNT = 101
) (
    output wire [TAP_CNT*32-1:0] coeff_bus
);

  assign coeff_bus = {
    32'h21a5e407, 32'h39a1fef1, 32'h3a0a48e5, 32'h3a14dc7c, 32'h39c9729c,
    32'h21373cac, 32'hb9fa686f, 32'hba647ae3, 32'hba815b49, 32'hba3564bc,
    32'ha2c126e6, 32'h3a696787, 32'h3ad5c178, 32'h3af17343, 32'h3aa82360,
    32'h239ded49, 32'hbad3be22, 32'hbb3f7379, 32'hbb556676, 32'hbb12a289,
    32'ha4439339, 32'h3b33fb1e, 32'h3ba0cd0c, 32'h3bb13ea7, 32'h3b71153f,
    32'ha30bf866, 32'hbb915883, 32'hbc00e7a5, 32'hbc0d333a, 32'hbbbf1429,
    32'ha3c43dcb, 32'h3be4ec47, 32'h3c4accff, 32'h3c5e3e69, 32'h3c16b483,
    32'h24c72eb7, 32'hbc367814, 32'hbca31ca3, 32'hbcb4ed9c, 32'hbc794bfe,
    32'ha403343e, 32'h3c9e21ad, 32'h3d1233f3, 32'h3d2969d5, 32'h3cf73d64,
    32'h240c9a35, 32'hbd3cd9b8, 32'hbdcd0395, 32'hbe1a7617, 32'hbe3f721e,
    32'h3f4cd56c,
    32'hbe3f721e, 32'hbe1a7617, 32'hbdcd0395, 32'hbd3cd9b8, 32'h240c9a35,
    32'h3cf73d64, 32'h3d2969d5, 32'h3d1233f3, 32'h3c9e21ad, 32'ha403343e,
    32'hbc794bfe, 32'hbcb4ed9c, 32'hbca31ca3, 32'hbc367814, 32'h24c72eb7,
    32'h3c16b483, 32'h3c5e3e69, 32'h3c4accff, 32'h3be4ec47, 32'ha3c43dcb,
    32'hbbbf1429, 32'hbc0d333a, 32'hbc00e7a5, 32'hbb915883, 32'ha30bf866,
    32'h3b71153f, 32'h3bb13ea7, 32'h3ba0cd0c, 32'h3b33fb1e, 32'ha4439339,
    32'hbb12a289, 32'hbb556676, 32'hbb3f7379, 32'hbad3be22, 32'h239ded49,
    32'h3aa82360, 32'h3af17343, 32'h3ad5c178, 32'h3a696787, 32'ha2c126e6,
    32'hba3564bc, 32'hba815b49, 32'hba647ae3, 32'hb9fa686f, 32'h21373cac,
    32'h39c9729c, 32'h3a14dc7c, 32'h3a0a48e5, 32'h39a1fef1, 32'h21a5e407
  };

endmodule