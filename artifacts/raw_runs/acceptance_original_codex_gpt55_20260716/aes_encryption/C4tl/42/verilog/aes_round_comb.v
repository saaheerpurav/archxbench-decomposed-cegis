module aes_round_comb (
    input      [127:0] state_in,
    input      [127:0] round_key,
    input              final_round,
    output     [127:0] state_out
);

  wire [7:0] b00, b01, b02, b03;
  wire [7:0] b04, b05, b06, b07;
  wire [7:0] b08, b09, b10, b11;
  wire [7:0] b12, b13, b14, b15;

  aes_sbox_byte s00 (.in(state_in[127:120]), .out(b00));
  aes_sbox_byte s01 (.in(state_in[119:112]), .out(b01));
  aes_sbox_byte s02 (.in(state_in[111:104]), .out(b02));
  aes_sbox_byte s03 (.in(state_in[103:96]),  .out(b03));

  aes_sbox_byte s04 (.in(state_in[95:88]),   .out(b04));
  aes_sbox_byte s05 (.in(state_in[87:80]),   .out(b05));
  aes_sbox_byte s06 (.in(state_in[79:72]),   .out(b06));
  aes_sbox_byte s07 (.in(state_in[71:64]),   .out(b07));

  aes_sbox_byte s08 (.in(state_in[63:56]),   .out(b08));
  aes_sbox_byte s09 (.in(state_in[55:48]),   .out(b09));
  aes_sbox_byte s10 (.in(state_in[47:40]),   .out(b10));
  aes_sbox_byte s11 (.in(state_in[39:32]),   .out(b11));

  aes_sbox_byte s12 (.in(state_in[31:24]),   .out(b12));
  aes_sbox_byte s13 (.in(state_in[23:16]),   .out(b13));
  aes_sbox_byte s14 (.in(state_in[15:8]),    .out(b14));
  aes_sbox_byte s15 (.in(state_in[7:0]),     .out(b15));

  wire [127:0] shifted;

  assign shifted = {
    b00, b05, b10, b15,
    b04, b09, b14, b03,
    b08, b13, b02, b07,
    b12, b01, b06, b11
  };

  function [7:0] xtime;
    input [7:0] x;
    begin
      xtime = {x[6:0], 1'b0} ^ ({8{x[7]}} & 8'h1b);
    end
  endfunction

  function [31:0] mix_col;
    input [31:0] c;

    reg [7:0] a0;
    reg [7:0] a1;
    reg [7:0] a2;
    reg [7:0] a3;

    reg [7:0] x0;
    reg [7:0] x1;
    reg [7:0] x2;
    reg [7:0] x3;

    begin
      a0 = c[31:24];
      a1 = c[23:16];
      a2 = c[15:8];
      a3 = c[7:0];

      x0 = xtime(a0);
      x1 = xtime(a1);
      x2 = xtime(a2);
      x3 = xtime(a3);

      mix_col = {
        x0 ^ (x1 ^ a1) ^ a2 ^ a3,
        a0 ^ x1 ^ (x2 ^ a2) ^ a3,
        a0 ^ a1 ^ x2 ^ (x3 ^ a3),
        (x0 ^ a0) ^ a1 ^ a2 ^ x3
      };
    end
  endfunction

  wire [127:0] mixed;

  assign mixed = {
    mix_col(shifted[127:96]),
    mix_col(shifted[95:64]),
    mix_col(shifted[63:32]),
    mix_col(shifted[31:0])
  };

  assign state_out = (final_round ? shifted : mixed) ^ round_key;

endmodule