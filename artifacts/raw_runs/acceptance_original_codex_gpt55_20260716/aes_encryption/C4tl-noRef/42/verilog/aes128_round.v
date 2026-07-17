module aes128_round (
    input  [127:0] state_in,
    input  [127:0] key_in,
    input  [7:0]   rcon,
    output [127:0] state_out,
    output [127:0] key_out
);

  wire [7:0] s0;
  wire [7:0] s1;
  wire [7:0] s2;
  wire [7:0] s3;
  wire [7:0] s4;
  wire [7:0] s5;
  wire [7:0] s6;
  wire [7:0] s7;
  wire [7:0] s8;
  wire [7:0] s9;
  wire [7:0] s10;
  wire [7:0] s11;
  wire [7:0] s12;
  wire [7:0] s13;
  wire [7:0] s14;
  wire [7:0] s15;

  aes128_sbox sb0  (.in(state_in[127:120]), .out(s0));
  aes128_sbox sb1  (.in(state_in[119:112]), .out(s1));
  aes128_sbox sb2  (.in(state_in[111:104]), .out(s2));
  aes128_sbox sb3  (.in(state_in[103:96]),  .out(s3));
  aes128_sbox sb4  (.in(state_in[95:88]),   .out(s4));
  aes128_sbox sb5  (.in(state_in[87:80]),   .out(s5));
  aes128_sbox sb6  (.in(state_in[79:72]),   .out(s6));
  aes128_sbox sb7  (.in(state_in[71:64]),   .out(s7));
  aes128_sbox sb8  (.in(state_in[63:56]),   .out(s8));
  aes128_sbox sb9  (.in(state_in[55:48]),   .out(s9));
  aes128_sbox sb10 (.in(state_in[47:40]),   .out(s10));
  aes128_sbox sb11 (.in(state_in[39:32]),   .out(s11));
  aes128_sbox sb12 (.in(state_in[31:24]),   .out(s12));
  aes128_sbox sb13 (.in(state_in[23:16]),   .out(s13));
  aes128_sbox sb14 (.in(state_in[15:8]),    .out(s14));
  aes128_sbox sb15 (.in(state_in[7:0]),     .out(s15));

  wire [127:0] shifted_state;

  assign shifted_state = {
      s0,  s5,  s10, s15,
      s4,  s9,  s14, s3,
      s8,  s13, s2,  s7,
      s12, s1,  s6,  s11
  };

  function [7:0] xtime;
    input [7:0] x;
    begin
      xtime = {x[6:0], 1'b0} ^ (8'h1b & {8{x[7]}});
    end
  endfunction

  function [7:0] mul2;
    input [7:0] x;
    begin
      mul2 = xtime(x);
    end
  endfunction

  function [7:0] mul3;
    input [7:0] x;
    begin
      mul3 = xtime(x) ^ x;
    end
  endfunction

  function [31:0] mix_column;
    input [31:0] col;
    reg [7:0] a0;
    reg [7:0] a1;
    reg [7:0] a2;
    reg [7:0] a3;
    begin
      a0 = col[31:24];
      a1 = col[23:16];
      a2 = col[15:8];
      a3 = col[7:0];

      mix_column[31:24] = mul2(a0) ^ mul3(a1) ^ a2      ^ a3;
      mix_column[23:16] = a0      ^ mul2(a1) ^ mul3(a2) ^ a3;
      mix_column[15:8]  = a0      ^ a1      ^ mul2(a2) ^ mul3(a3);
      mix_column[7:0]   = mul3(a0) ^ a1     ^ a2      ^ mul2(a3);
    end
  endfunction

  wire [127:0] mixed_state;

  assign mixed_state = {
      mix_column(shifted_state[127:96]),
      mix_column(shifted_state[95:64]),
      mix_column(shifted_state[63:32]),
      mix_column(shifted_state[31:0])
  };

  wire [31:0] w0;
  wire [31:0] w1;
  wire [31:0] w2;
  wire [31:0] w3;

  assign w0 = key_in[127:96];
  assign w1 = key_in[95:64];
  assign w2 = key_in[63:32];
  assign w3 = key_in[31:0];

  wire [7:0] ksub0;
  wire [7:0] ksub1;
  wire [7:0] ksub2;
  wire [7:0] ksub3;

  aes128_sbox ksb0 (.in(w3[23:16]), .out(ksub0));
  aes128_sbox ksb1 (.in(w3[15:8]),  .out(ksub1));
  aes128_sbox ksb2 (.in(w3[7:0]),   .out(ksub2));
  aes128_sbox ksb3 (.in(w3[31:24]), .out(ksub3));

  wire [31:0] gword;
  wire [31:0] nw0;
  wire [31:0] nw1;
  wire [31:0] nw2;
  wire [31:0] nw3;

  assign gword = {ksub0 ^ rcon, ksub1, ksub2, ksub3};

  assign nw0 = w0 ^ gword;
  assign nw1 = w1 ^ nw0;
  assign nw2 = w2 ^ nw1;
  assign nw3 = w3 ^ nw2;

  assign key_out   = {nw0, nw1, nw2, nw3};
  assign state_out = mixed_state ^ key_out;

endmodule