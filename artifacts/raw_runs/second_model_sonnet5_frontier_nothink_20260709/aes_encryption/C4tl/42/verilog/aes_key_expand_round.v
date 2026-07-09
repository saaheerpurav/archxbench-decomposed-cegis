module aes_key_expand_round (
    input      [127:0] round_key_in,
    input      [3:0]   round_idx,   // 1..10
    output     [127:0] round_key_out
);
    // Extract 4 words (w0,w1,w2,w3), MSB word first
    wire [31:0] w0 = round_key_in[127:96];
    wire [31:0] w1 = round_key_in[95:64];
    wire [31:0] w2 = round_key_in[63:32];
    wire [31:0] w3 = round_key_in[31:0];

    // RotWord(w3): rotate left by 8 bits
    wire [31:0] rot_w3 = {w3[23:0], w3[31:24]};

    // SubWord via sbox on each byte
    wire [7:0] sb0, sb1, sb2, sb3;
    aes_sbox s0(.in_byte(rot_w3[31:24]), .out_byte(sb0));
    aes_sbox s1(.in_byte(rot_w3[23:16]), .out_byte(sb1));
    aes_sbox s2(.in_byte(rot_w3[15:8]),  .out_byte(sb2));
    aes_sbox s3(.in_byte(rot_w3[7:0]),   .out_byte(sb3));

    wire [31:0] sub_w3 = {sb0, sb1, sb2, sb3};

    // Rcon lookup
    function [7:0] rcon_val;
        input [3:0] idx;
        begin
            case (idx)
                4'd1:  rcon_val = 8'h01;
                4'd2:  rcon_val = 8'h02;
                4'd3:  rcon_val = 8'h04;
                4'd4:  rcon_val = 8'h08;
                4'd5:  rcon_val = 8'h10;
                4'd6:  rcon_val = 8'h20;
                4'd7:  rcon_val = 8'h40;
                4'd8:  rcon_val = 8'h80;
                4'd9:  rcon_val = 8'h1b;
                4'd10: rcon_val = 8'h36;
                default: rcon_val = 8'h00;
            endcase
        end
    endfunction

    wire [31:0] rcon_word = {rcon_val(round_idx), 8'h00, 8'h00, 8'h00};

    wire [31:0] new_w0 = w0 ^ sub_w3 ^ rcon_word;
    wire [31:0] new_w1 = new_w0 ^ w1;
    wire [31:0] new_w2 = new_w1 ^ w2;
    wire [31:0] new_w3 = new_w2 ^ w3;

    assign round_key_out = {new_w0, new_w1, new_w2, new_w3};

endmodule