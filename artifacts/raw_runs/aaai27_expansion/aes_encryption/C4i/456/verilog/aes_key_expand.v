`timescale 1ns/1ps

module aes_key_expand (
    input  [127:0] key_in,
    input  [3:0]   round,
    output [127:0] key_out
);
    wire [31:0] w0;
    wire [31:0] w1;
    wire [31:0] w2;
    wire [31:0] w3;

    wire [31:0] rotword;
    wire [7:0]  sb0;
    wire [7:0]  sb1;
    wire [7:0]  sb2;
    wire [7:0]  sb3;
    wire [31:0] subword;

    reg  [7:0]  rcon;

    wire [31:0] temp;
    wire [31:0] nw0;
    wire [31:0] nw1;
    wire [31:0] nw2;
    wire [31:0] nw3;

    assign w0 = key_in[127:96];
    assign w1 = key_in[95:64];
    assign w2 = key_in[63:32];
    assign w3 = key_in[31:0];

    assign rotword = {w3[23:0], w3[31:24]};

    aes_sbox sbox0 (.in(rotword[31:24]), .out(sb0));
    aes_sbox sbox1 (.in(rotword[23:16]), .out(sb1));
    aes_sbox sbox2 (.in(rotword[15:8]),  .out(sb2));
    aes_sbox sbox3 (.in(rotword[7:0]),   .out(sb3));

    assign subword = {sb0, sb1, sb2, sb3};

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

    assign temp = subword ^ {rcon, 24'h000000};

    assign nw0 = w0 ^ temp;
    assign nw1 = w1 ^ nw0;
    assign nw2 = w2 ^ nw1;
    assign nw3 = w3 ^ nw2;

    assign key_out = {nw0, nw1, nw2, nw3};

endmodule