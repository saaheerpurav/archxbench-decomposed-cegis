`timescale 1ns/1ps

module aes_key_expand (
    input      [3:0]   round,
    input      [127:0] key_in,
    output     [127:0] key_out
);

  wire [31:0] w0;
  wire [31:0] w1;
  wire [31:0] w2;
  wire [31:0] w3;

  wire [31:0] rot_word;
  wire [31:0] sub_word;
  reg  [31:0] rcon;

  wire [31:0] nw0;
  wire [31:0] nw1;
  wire [31:0] nw2;
  wire [31:0] nw3;

  assign w0 = key_in[127:96];
  assign w1 = key_in[95:64];
  assign w2 = key_in[63:32];
  assign w3 = key_in[31:0];

  assign rot_word = {w3[23:0], w3[31:24]};

  aes_sbox sbox0 (
    .in  (rot_word[31:24]),
    .out (sub_word[31:24])
  );

  aes_sbox sbox1 (
    .in  (rot_word[23:16]),
    .out (sub_word[23:16])
  );

  aes_sbox sbox2 (
    .in  (rot_word[15:8]),
    .out (sub_word[15:8])
  );

  aes_sbox sbox3 (
    .in  (rot_word[7:0]),
    .out (sub_word[7:0])
  );

  always @* begin
    case (round)
      4'd1:  rcon = 32'h01000000;
      4'd2:  rcon = 32'h02000000;
      4'd3:  rcon = 32'h04000000;
      4'd4:  rcon = 32'h08000000;
      4'd5:  rcon = 32'h10000000;
      4'd6:  rcon = 32'h20000000;
      4'd7:  rcon = 32'h40000000;
      4'd8:  rcon = 32'h80000000;
      4'd9:  rcon = 32'h1b000000;
      4'd10: rcon = 32'h36000000;
      default: rcon = 32'h00000000;
    endcase
  end

  assign nw0 = w0 ^ sub_word ^ rcon;
  assign nw1 = w1 ^ nw0;
  assign nw2 = w2 ^ nw1;
  assign nw3 = w3 ^ nw2;

  assign key_out = {nw0, nw1, nw2, nw3};

endmodule