module aes_key_expand_round (
    input  [127:0] prev_key,
    input  [7:0]   rcon,
    output [127:0] next_key
);
    // words: w0 = bits [127:96], w1=[95:64], w2=[63:32], w3=[31:0]
    wire [31:0] w0 = prev_key[127:96];
    wire [31:0] w1 = prev_key[95:64];
    wire [31:0] w2 = prev_key[63:32];
    wire [31:0] w3 = prev_key[31:0];

    // RotWord(w3): rotate left by 8 bits
    wire [31:0] rot_w3 = {w3[23:0], w3[31:24]};

    // SubWord
    wire [7:0] sb0, sb1, sb2, sb3;
    aes_sbox s0(.in_byte(rot_w3[31:24]), .out_byte(sb0));
    aes_sbox s1(.in_byte(rot_w3[23:16]), .out_byte(sb1));
    aes_sbox s2(.in_byte(rot_w3[15:8]),  .out_byte(sb2));
    aes_sbox s3(.in_byte(rot_w3[7:0]),   .out_byte(sb3));

    wire [31:0] sub_word = {sb0, sb1, sb2, sb3};
    wire [31:0] rcon_word = {rcon, 24'h000000};

    wire [31:0] temp = sub_word ^ rcon_word;

    wire [31:0] w4 = w0 ^ temp;
    wire [31:0] w5 = w4 ^ w1;
    wire [31:0] w6 = w5 ^ w2;
    wire [31:0] w7 = w6 ^ w3;

    assign next_key = {w4, w5, w6, w7};

endmodule