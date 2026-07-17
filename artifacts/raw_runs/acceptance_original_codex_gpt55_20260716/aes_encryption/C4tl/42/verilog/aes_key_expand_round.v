module aes_key_expand_round (
    input      [3:0]   round,
    input      [127:0] key_in,
    output     [127:0] key_out
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

  aes_sbox_byte sb0 (
      .in  (w3[23:16]),
      .out (sub0)
  );

  aes_sbox_byte sb1 (
      .in  (w3[15:8]),
      .out (sub1)
  );

  aes_sbox_byte sb2 (
      .in  (w3[7:0]),
      .out (sub2)
  );

  aes_sbox_byte sb3 (
      .in  (w3[31:24]),
      .out (sub3)
  );

  reg [7:0] rcon;

  always @* begin
    case (round)
      4'd1:    rcon = 8'h01;
      4'd2:    rcon = 8'h02;
      4'd3:    rcon = 8'h04;
      4'd4:    rcon = 8'h08;
      4'd5:    rcon = 8'h10;
      4'd6:    rcon = 8'h20;
      4'd7:    rcon = 8'h40;
      4'd8:    rcon = 8'h80;
      4'd9:    rcon = 8'h1b;
      4'd10:   rcon = 8'h36;
      default: rcon = 8'h00;
    endcase
  end

  wire [31:0] gword;
  wire [31:0] nw0;
  wire [31:0] nw1;
  wire [31:0] nw2;
  wire [31:0] nw3;

  assign gword = {sub0 ^ rcon, sub1, sub2, sub3};

  assign nw0 = w0 ^ gword;
  assign nw1 = w1 ^ nw0;
  assign nw2 = w2 ^ nw1;
  assign nw3 = w3 ^ nw2;

  assign key_out = {nw0, nw1, nw2, nw3};

endmodule