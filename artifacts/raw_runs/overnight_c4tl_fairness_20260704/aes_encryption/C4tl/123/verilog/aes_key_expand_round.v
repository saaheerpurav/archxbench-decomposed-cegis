`timescale 1ns/1ps

module aes_key_expand_round (
    input      [127:0] key_in,
    input      [3:0]   round,
    output     [127:0] key_out
);
    wire [31:0] w0;
    wire [31:0] w1;
    wire [31:0] w2;
    wire [31:0] w3;

    wire [31:0] rot_word;
    wire [7:0]  sub0;
    wire [7:0]  sub1;
    wire [7:0]  sub2;
    wire [7:0]  sub3;
    wire [7:0]  rcon;

    wire [31:0] g;
    wire [31:0] nw0;
    wire [31:0] nw1;
    wire [31:0] nw2;
    wire [31:0] nw3;

    assign w0 = key_in[127:96];
    assign w1 = key_in[95:64];
    assign w2 = key_in[63:32];
    assign w3 = key_in[31:0];

    assign rot_word = {w3[23:0], w3[31:24]};

    aes_sbox sbox0 (.byte_in(rot_word[31:24]), .byte_out(sub0));
    aes_sbox sbox1 (.byte_in(rot_word[23:16]), .byte_out(sub1));
    aes_sbox sbox2 (.byte_in(rot_word[15:8]),  .byte_out(sub2));
    aes_sbox sbox3 (.byte_in(rot_word[7:0]),   .byte_out(sub3));

    assign rcon = (round == 4'd1)  ? 8'h01 :
                  (round == 4'd2)  ? 8'h02 :
                  (round == 4'd3)  ? 8'h04 :
                  (round == 4'd4)  ? 8'h08 :
                  (round == 4'd5)  ? 8'h10 :
                  (round == 4'd6)  ? 8'h20 :
                  (round == 4'd7)  ? 8'h40 :
                  (round == 4'd8)  ? 8'h80 :
                  (round == 4'd9)  ? 8'h1b :
                  (round == 4'd10) ? 8'h36 :
                                      8'h00;

    assign g = {sub0 ^ rcon, sub1, sub2, sub3};

    assign nw0 = w0 ^ g;
    assign nw1 = w1 ^ nw0;
    assign nw2 = w2 ^ nw1;
    assign nw3 = w3 ^ nw2;

    assign key_out = {nw0, nw1, nw2, nw3};

endmodule