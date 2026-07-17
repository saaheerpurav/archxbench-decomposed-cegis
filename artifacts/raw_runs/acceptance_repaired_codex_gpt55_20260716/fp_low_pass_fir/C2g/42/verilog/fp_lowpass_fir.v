`timescale 1ns/1ps

module fp_lowpass_fir #(
    parameter TAP_CNT = 101
) (
    input wire clk,
    input wire rst,
    input wire valid_in,
    input wire [31:0] data_in,
    output reg valid_out,
    output reg [31:0] data_out
);

  reg [31:0] delay_line [0:TAP_CNT-1];
  reg [31:0] coeff_bits [0:TAP_CNT-1];

  integer i;
  shortreal acc;

  initial begin
    coeff_bits[  0] = 32'ha012b177;
    coeff_bits[  1] = 32'hb8899b4e;
    coeff_bits[  2] = 32'hb9100cde;
    coeff_bits[  3] = 32'hb9658a36;
    coeff_bits[  4] = 32'hb9a46f97;
    coeff_bits[  5] = 32'hb9de9774;
    coeff_bits[  6] = 32'hba1138b0;
    coeff_bits[  7] = 32'hba385a59;
    coeff_bits[  8] = 32'hba64beaf;
    coeff_bits[  9] = 32'hba8b0c70;
    coeff_bits[ 10] = 32'hbaa5db4a;
    coeff_bits[ 11] = 32'hbac23c16;
    coeff_bits[ 12] = 32'hbadf6632;
    coeff_bits[ 13] = 32'hbafc57d6;
    coeff_bits[ 14] = 32'hbb0bebe1;
    coeff_bits[ 15] = 32'hbb183c76;
    coeff_bits[ 16] = 32'hbb225021;
    coeff_bits[ 17] = 32'hbb29462d;
    coeff_bits[ 18] = 32'hbb2c2f7f;
    coeff_bits[ 19] = 32'hbb2a1427;
    coeff_bits[ 20] = 32'hbb21f9a9;
    coeff_bits[ 21] = 32'hbb12e9c7;
    coeff_bits[ 22] = 32'hbaf7f357;
    coeff_bits[ 23] = 32'hbab8a276;
    coeff_bits[ 24] = 32'hba4cc970;
    coeff_bits[ 25] = 32'h21778b78;
    coeff_bits[ 26] = 32'h3a76ed36;
    coeff_bits[ 27] = 32'h3b064780;
    coeff_bits[ 28] = 32'h3b59ba00;
    coeff_bits[ 29] = 32'h3b9bf8d7;
    coeff_bits[ 30] = 32'h3bd04a05;
    coeff_bits[ 31] = 32'h3c04c2ee;
    coeff_bits[ 32] = 32'h3c23a218;
    coeff_bits[ 33] = 32'h3c447ffc;
    coeff_bits[ 34] = 32'h3c670c62;
    coeff_bits[ 35] = 32'h3c857531;
    coeff_bits[ 36] = 32'h3c97d8e8;
    coeff_bits[ 37] = 32'h3caa7876;
    coeff_bits[ 38] = 32'h3cbd1733;
    coeff_bits[ 39] = 32'h3ccf75c9;
    coeff_bits[ 40] = 32'h3ce1536a;
    coeff_bits[ 41] = 32'h3cf26f15;
    coeff_bits[ 42] = 32'h3d014471;
    coeff_bits[ 43] = 32'h3d08b1ac;
    coeff_bits[ 44] = 32'h3d0f6255;
    coeff_bits[ 45] = 32'h3d153bfc;
    coeff_bits[ 46] = 32'h3d1a2735;
    coeff_bits[ 47] = 32'h3d1e101a;
    coeff_bits[ 48] = 32'h3d20e6b9;
    coeff_bits[ 49] = 32'h3d229f6d;
    coeff_bits[ 50] = 32'h3d23331f;
    coeff_bits[ 51] = 32'h3d229f6d;
    coeff_bits[ 52] = 32'h3d20e6b9;
    coeff_bits[ 53] = 32'h3d1e101a;
    coeff_bits[ 54] = 32'h3d1a2735;
    coeff_bits[ 55] = 32'h3d153bfc;
    coeff_bits[ 56] = 32'h3d0f6255;
    coeff_bits[ 57] = 32'h3d08b1ac;
    coeff_bits[ 58] = 32'h3d014471;
    coeff_bits[ 59] = 32'h3cf26f15;
    coeff_bits[ 60] = 32'h3ce1536a;
    coeff_bits[ 61] = 32'h3ccf75c9;
    coeff_bits[ 62] = 32'h3cbd1733;
    coeff_bits[ 63] = 32'h3caa7876;
    coeff_bits[ 64] = 32'h3c97d8e8;
    coeff_bits[ 65] = 32'h3c857531;
    coeff_bits[ 66] = 32'h3c670c62;
    coeff_bits[ 67] = 32'h3c447ffc;
    coeff_bits[ 68] = 32'h3c23a218;
    coeff_bits[ 69] = 32'h3c04c2ee;
    coeff_bits[ 70] = 32'h3bd04a05;
    coeff_bits[ 71] = 32'h3b9bf8d7;
    coeff_bits[ 72] = 32'h3b59ba00;
    coeff_bits[ 73] = 32'h3b064780;
    coeff_bits[ 74] = 32'h3a76ed36;
    coeff_bits[ 75] = 32'h21778b78;
    coeff_bits[ 76] = 32'hba4cc970;
    coeff_bits[ 77] = 32'hbab8a276;
    coeff_bits[ 78] = 32'hbaf7f357;
    coeff_bits[ 79] = 32'hbb12e9c7;
    coeff_bits[ 80] = 32'hbb21f9a9;
    coeff_bits[ 81] = 32'hbb2a1427;
    coeff_bits[ 82] = 32'hbb2c2f7f;
    coeff_bits[ 83] = 32'hbb29462d;
    coeff_bits[ 84] = 32'hbb225021;
    coeff_bits[ 85] = 32'hbb183c76;
    coeff_bits[ 86] = 32'hbb0bebe1;
    coeff_bits[ 87] = 32'hbafc57d6;
    coeff_bits[ 88] = 32'hbadf6632;
    coeff_bits[ 89] = 32'hbac23c16;
    coeff_bits[ 90] = 32'hbaa5db4a;
    coeff_bits[ 91] = 32'hba8b0c70;
    coeff_bits[ 92] = 32'hba64beaf;
    coeff_bits[ 93] = 32'hba385a59;
    coeff_bits[ 94] = 32'hba1138b0;
    coeff_bits[ 95] = 32'hb9de9774;
    coeff_bits[ 96] = 32'hb9a46f97;
    coeff_bits[ 97] = 32'hb9658a36;
    coeff_bits[ 98] = 32'hb9100cde;
    coeff_bits[ 99] = 32'hb8899b4e;
    coeff_bits[100] = 32'ha012b177;
  end

  always @(posedge clk) begin
    if (rst) begin
      valid_out <= 1'b0;
      data_out <= 32'h00000000;
      for (i = 0; i < TAP_CNT; i = i + 1)
        delay_line[i] <= 32'h00000000;
    end else begin
      valid_out <= valid_in;

      if (valid_in) begin
        acc = $bitstoshortreal(data_in) * $bitstoshortreal(coeff_bits[0]);

        for (i = 1; i < TAP_CNT; i = i + 1)
          acc = acc + ($bitstoshortreal(delay_line[i-1]) * $bitstoshortreal(coeff_bits[i]));

        data_out <= $shortrealtobits(acc);

        for (i = TAP_CNT-1; i > 0; i = i - 1)
          delay_line[i] <= delay_line[i-1];

        delay_line[0] <= data_in;
      end
    end
  end

endmodule