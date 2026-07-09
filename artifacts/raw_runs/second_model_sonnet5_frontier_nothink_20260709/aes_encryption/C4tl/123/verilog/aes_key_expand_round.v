module aes_key_expand_round (
    input      [127:0] key_in,
    input      [7:0]   rcon,
    output     [127:0] key_out
);
    // key_in split into 4 words w0,w1,w2,w3 (w0 = MSB)
    wire [31:0] w0 = key_in[127:96];
    wire [31:0] w1 = key_in[95:64];
    wire [31:0] w2 = key_in[63:32];
    wire [31:0] w3 = key_in[31:0];

    // RotWord(w3): rotate left by 8 bits
    wire [31:0] rot_w3 = {w3[23:0], w3[31:24]};

    // SubWord
    wire [7:0] sb_in0 = rot_w3[31:24];
    wire [7:0] sb_in1 = rot_w3[23:16];
    wire [7:0] sb_in2 = rot_w3[15:8];
    wire [7:0] sb_in3 = rot_w3[7:0];

    wire [7:0] sb_out0, sb_out1, sb_out2, sb_out3;

    aes_sbox u_s0 (.byte_in(sb_in0), .byte_out(sb_out0));
    aes_sbox u_s1 (.byte_in(sb_in1), .byte_out(sb_out1));
    aes_sbox u_s2 (.byte_in(sb_in2), .byte_out(sb_out2));
    aes_sbox u_s3 (.byte_in(sb_in3), .byte_out(sb_out3));

    wire [31:0] sub_word = {sb_out0, sb_out1, sb_out2, sb_out3};

    wire [31:0] rcon_word = {rcon, 24'h000000};

    wire [31:0] w4 = w0 ^ sub_word ^ rcon_word;
    wire [31:0] w5 = w4 ^ w1;
    wire [31:0] w6 = w5 ^ w2;
    wire [31:0] w7 = w6 ^ w3;

    assign key_out = {w4, w5, w6, w7};

endmodule