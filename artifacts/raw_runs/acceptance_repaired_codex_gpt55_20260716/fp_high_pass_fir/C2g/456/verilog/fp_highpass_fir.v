`timescale 1ns/1ps

module fp_highpass_fir #(
    parameter TAP_CNT = 101
) (
    input wire clk,
    input wire rst,
    input wire valid_in,
    input wire [31:0] data_in,
    output wire valid_out,
    output wire [31:0] data_out
);

  localparam integer COEFF_CNT = 101;

  reg out_valid_r;
  reg [31:0] out_data_r;

  reg [31:0] x_hist [0:COEFF_CNT-1];
  reg [31:0] coeff  [0:COEFF_CNT-1];

  integer i;
  integer k;

  shortreal acc;
  shortreal prod;
  shortreal sx;
  shortreal sh;

  assign valid_out = out_valid_r;
  assign data_out  = out_data_r;

  initial begin
    coeff[  0] = 32'h21a5e407;
    coeff[  1] = 32'h39a1fef1;
    coeff[  2] = 32'h3a0a48e5;
    coeff[  3] = 32'h3a14dc7c;
    coeff[  4] = 32'h39c9729c;
    coeff[  5] = 32'h21373cac;
    coeff[  6] = 32'hb9fa686f;
    coeff[  7] = 32'hba647ae3;
    coeff[  8] = 32'hba815b49;
    coeff[  9] = 32'hba3564bc;
    coeff[ 10] = 32'ha2c126e6;
    coeff[ 11] = 32'h3a696787;
    coeff[ 12] = 32'h3ad5c178;
    coeff[ 13] = 32'h3af17343;
    coeff[ 14] = 32'h3aa82360;
    coeff[ 15] = 32'h239ded49;
    coeff[ 16] = 32'hbad3be22;
    coeff[ 17] = 32'hbb3f7379;
    coeff[ 18] = 32'hbb556676;
    coeff[ 19] = 32'hbb12a289;
    coeff[ 20] = 32'ha4439339;
    coeff[ 21] = 32'h3b33fb1e;
    coeff[ 22] = 32'h3ba0cd0c;
    coeff[ 23] = 32'h3bb13ea7;
    coeff[ 24] = 32'h3b71153f;
    coeff[ 25] = 32'ha30bf866;
    coeff[ 26] = 32'hbb915883;
    coeff[ 27] = 32'hbc00e7a5;
    coeff[ 28] = 32'hbc0d333a;
    coeff[ 29] = 32'hbbbf1429;
    coeff[ 30] = 32'ha3c43dcb;
    coeff[ 31] = 32'h3be4ec47;
    coeff[ 32] = 32'h3c4accff;
    coeff[ 33] = 32'h3c5e3e69;
    coeff[ 34] = 32'h3c16b483;
    coeff[ 35] = 32'h24c72eb7;
    coeff[ 36] = 32'hbc367814;
    coeff[ 37] = 32'hbca31ca3;
    coeff[ 38] = 32'hbcb4ed9c;
    coeff[ 39] = 32'hbc794bfe;
    coeff[ 40] = 32'ha403343e;
    coeff[ 41] = 32'h3c9e21ad;
    coeff[ 42] = 32'h3d1233f3;
    coeff[ 43] = 32'h3d2969d5;
    coeff[ 44] = 32'h3cf73d64;
    coeff[ 45] = 32'h240c9a35;
    coeff[ 46] = 32'hbd3cd9b8;
    coeff[ 47] = 32'hbdcd0395;
    coeff[ 48] = 32'hbe1a7617;
    coeff[ 49] = 32'hbe3f721e;
    coeff[ 50] = 32'h3f4cd56c;
    coeff[ 51] = 32'hbe3f721e;
    coeff[ 52] = 32'hbe1a7617;
    coeff[ 53] = 32'hbdcd0395;
    coeff[ 54] = 32'hbd3cd9b8;
    coeff[ 55] = 32'h240c9a35;
    coeff[ 56] = 32'h3cf73d64;
    coeff[ 57] = 32'h3d2969d5;
    coeff[ 58] = 32'h3d1233f3;
    coeff[ 59] = 32'h3c9e21ad;
    coeff[ 60] = 32'ha403343e;
    coeff[ 61] = 32'hbc794bfe;
    coeff[ 62] = 32'hbcb4ed9c;
    coeff[ 63] = 32'hbca31ca3;
    coeff[ 64] = 32'hbc367814;
    coeff[ 65] = 32'h24c72eb7;
    coeff[ 66] = 32'h3c16b483;
    coeff[ 67] = 32'h3c5e3e69;
    coeff[ 68] = 32'h3c4accff;
    coeff[ 69] = 32'h3be4ec47;
    coeff[ 70] = 32'ha3c43dcb;
    coeff[ 71] = 32'hbbbf1429;
    coeff[ 72] = 32'hbc0d333a;
    coeff[ 73] = 32'hbc00e7a5;
    coeff[ 74] = 32'hbb915883;
    coeff[ 75] = 32'ha30bf866;
    coeff[ 76] = 32'h3b71153f;
    coeff[ 77] = 32'h3bb13ea7;
    coeff[ 78] = 32'h3ba0cd0c;
    coeff[ 79] = 32'h3b33fb1e;
    coeff[ 80] = 32'ha4439339;
    coeff[ 81] = 32'hbb12a289;
    coeff[ 82] = 32'hbb556676;
    coeff[ 83] = 32'hbb3f7379;
    coeff[ 84] = 32'hbad3be22;
    coeff[ 85] = 32'h239ded49;
    coeff[ 86] = 32'h3aa82360;
    coeff[ 87] = 32'h3af17343;
    coeff[ 88] = 32'h3ad5c178;
    coeff[ 89] = 32'h3a696787;
    coeff[ 90] = 32'ha2c126e6;
    coeff[ 91] = 32'hba3564bc;
    coeff[ 92] = 32'hba815b49;
    coeff[ 93] = 32'hba647ae3;
    coeff[ 94] = 32'hb9fa686f;
    coeff[ 95] = 32'h21373cac;
    coeff[ 96] = 32'h39c9729c;
    coeff[ 97] = 32'h3a14dc7c;
    coeff[ 98] = 32'h3a0a48e5;
    coeff[ 99] = 32'h39a1fef1;
    coeff[100] = 32'h21a5e407;
  end

  always @(posedge clk) begin
    if (rst) begin
      out_valid_r <= 1'b0;
      out_data_r  <= 32'h00000000;
      for (i = 0; i < COEFF_CNT; i = i + 1)
        x_hist[i] <= 32'h00000000;
    end else begin
      out_valid_r <= valid_in;

      if (valid_in) begin
        acc = 0.0;

        for (k = 0; k < COEFF_CNT; k = k + 1) begin
          if (k < TAP_CNT) begin
            sx = (k == 0) ? $bitstoshortreal(data_in) : $bitstoshortreal(x_hist[k-1]);
            sh = $bitstoshortreal(coeff[k]);
            prod = sx * sh;
            acc = acc + prod;
          end
        end

        out_data_r <= $shortrealtobits(acc);

        for (i = COEFF_CNT-1; i > 0; i = i - 1)
          x_hist[i] <= x_hist[i-1];
        x_hist[0] <= data_in;
      end
    end
  end

endmodule