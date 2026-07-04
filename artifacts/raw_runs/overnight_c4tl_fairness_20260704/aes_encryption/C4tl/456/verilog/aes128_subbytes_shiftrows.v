module aes128_subbytes_shiftrows (
    input  [127:0] state_in,
    output [127:0] state_out
);

  wire [7:0] b0  = state_in[127:120];
  wire [7:0] b1  = state_in[119:112];
  wire [7:0] b2  = state_in[111:104];
  wire [7:0] b3  = state_in[103:96];
  wire [7:0] b4  = state_in[95:88];
  wire [7:0] b5  = state_in[87:80];
  wire [7:0] b6  = state_in[79:72];
  wire [7:0] b7  = state_in[71:64];
  wire [7:0] b8  = state_in[63:56];
  wire [7:0] b9  = state_in[55:48];
  wire [7:0] b10 = state_in[47:40];
  wire [7:0] b11 = state_in[39:32];
  wire [7:0] b12 = state_in[31:24];
  wire [7:0] b13 = state_in[23:16];
  wire [7:0] b14 = state_in[15:8];
  wire [7:0] b15 = state_in[7:0];

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

  aes128_sbox sbox0  (.in(b0),  .out(s0));
  aes128_sbox sbox1  (.in(b1),  .out(s1));
  aes128_sbox sbox2  (.in(b2),  .out(s2));
  aes128_sbox sbox3  (.in(b3),  .out(s3));
  aes128_sbox sbox4  (.in(b4),  .out(s4));
  aes128_sbox sbox5  (.in(b5),  .out(s5));
  aes128_sbox sbox6  (.in(b6),  .out(s6));
  aes128_sbox sbox7  (.in(b7),  .out(s7));
  aes128_sbox sbox8  (.in(b8),  .out(s8));
  aes128_sbox sbox9  (.in(b9),  .out(s9));
  aes128_sbox sbox10 (.in(b10), .out(s10));
  aes128_sbox sbox11 (.in(b11), .out(s11));
  aes128_sbox sbox12 (.in(b12), .out(s12));
  aes128_sbox sbox13 (.in(b13), .out(s13));
  aes128_sbox sbox14 (.in(b14), .out(s14));
  aes128_sbox sbox15 (.in(b15), .out(s15));

  assign state_out = {
    s0,  s5,  s10, s15,
    s4,  s9,  s14, s3,
    s8,  s13, s2,  s7,
    s12, s1,  s6,  s11
  };

endmodule