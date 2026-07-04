module aes128_key_expand (
    input  [127:0] key_in,
    input  [7:0]   rcon,
    output [127:0] key_out
);

  wire [31:0] w0;
  wire [31:0] w1;
  wire [31:0] w2;
  wire [31:0] w3;

  assign w0 = key_in[127:96];
  assign w1 = key_in[95:64];
  assign w2 = key_in[63:32];
  assign w3 = key_in[31:0];

  wire [7:0] sub0;
  wire [7:0] sub1;
  wire [7:0] sub2;
  wire [7:0] sub3;

  aes128_sbox sb0 (
      .in  (w3[23:16]),
      .out (sub0)
  );

  aes128_sbox sb1 (
      .in  (w3[15:8]),
      .out (sub1)
  );

  aes128_sbox sb2 (
      .in  (w3[7:0]),
      .out (sub2)
  );

  aes128_sbox sb3 (
      .in  (w3[31:24]),
      .out (sub3)
  );

  wire [31:0] g;
  wire [31:0] nw0;
  wire [31:0] nw1;
  wire [31:0] nw2;
  wire [31:0] nw3;

  assign g   = {sub0 ^ rcon, sub1, sub2, sub3};

  assign nw0 = w0 ^ g;
  assign nw1 = w1 ^ nw0;
  assign nw2 = w2 ^ nw1;
  assign nw3 = w3 ^ nw2;

  assign key_out = {nw0, nw1, nw2, nw3};

endmodule