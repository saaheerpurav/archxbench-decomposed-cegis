`timescale 1ns/1ps

module aes128_key_expand (
    input  [127:0]  key_in,
    output reg [1407:0] round_keys
);
    reg [31:0] w [0:43];
    integer i;
    integer r;

    function [7:0] gf_mul;
        input [7:0] a;
        input [7:0] b;
        reg [7:0] aa;
        reg [7:0] bb;
        reg [7:0] p;
        integer j;
        begin
            aa = a;
            bb = b;
            p  = 8'h00;
            for (j = 0; j < 8; j = j + 1) begin
                if (bb[0])
                    p = p ^ aa;

                if (aa[7])
                    aa = (aa << 1) ^ 8'h1b;
                else
                    aa = aa << 1;

                bb = bb >> 1;
            end
            gf_mul = p;
        end
    endfunction

    function [7:0] gf_inv;
        input [7:0] x;
        reg [7:0] y;
        integer j;
        begin
            if (x == 8'h00) begin
                gf_inv = 8'h00;
            end else begin
                y = 8'h01;
                for (j = 0; j < 254; j = j + 1)
                    y = gf_mul(y, x);
                gf_inv = y;
            end
        end
    endfunction

    function [7:0] sbox;
        input [7:0] x;
        reg [7:0] b;
        reg [7:0] y;
        begin
            b = gf_inv(x);

            y[0] = b[0] ^ b[4] ^ b[5] ^ b[6] ^ b[7] ^ 1'b1;
            y[1] = b[1] ^ b[5] ^ b[6] ^ b[7] ^ b[0] ^ 1'b1;
            y[2] = b[2] ^ b[6] ^ b[7] ^ b[0] ^ b[1] ^ 1'b0;
            y[3] = b[3] ^ b[7] ^ b[0] ^ b[1] ^ b[2] ^ 1'b0;
            y[4] = b[4] ^ b[0] ^ b[1] ^ b[2] ^ b[3] ^ 1'b0;
            y[5] = b[5] ^ b[1] ^ b[2] ^ b[3] ^ b[4] ^ 1'b1;
            y[6] = b[6] ^ b[2] ^ b[3] ^ b[4] ^ b[5] ^ 1'b1;
            y[7] = b[7] ^ b[3] ^ b[4] ^ b[5] ^ b[6] ^ 1'b0;

            sbox = y;
        end
    endfunction

    function [31:0] subword;
        input [31:0] x;
        begin
            subword = {
                sbox(x[31:24]),
                sbox(x[23:16]),
                sbox(x[15:8]),
                sbox(x[7:0])
            };
        end
    endfunction

    function [31:0] rotword;
        input [31:0] x;
        begin
            rotword = {x[23:0], x[31:24]};
        end
    endfunction

    function [31:0] rcon;
        input integer n;
        begin
            case (n)
                1:  rcon = 32'h01000000;
                2:  rcon = 32'h02000000;
                3:  rcon = 32'h04000000;
                4:  rcon = 32'h08000000;
                5:  rcon = 32'h10000000;
                6:  rcon = 32'h20000000;
                7:  rcon = 32'h40000000;
                8:  rcon = 32'h80000000;
                9:  rcon = 32'h1b000000;
                10: rcon = 32'h36000000;
                default: rcon = 32'h00000000;
            endcase
        end
    endfunction

    always @* begin
        w[0] = key_in[127:96];
        w[1] = key_in[95:64];
        w[2] = key_in[63:32];
        w[3] = key_in[31:0];

        for (i = 4; i < 44; i = i + 1) begin
            if ((i % 4) == 0)
                w[i] = w[i-4] ^ subword(rotword(w[i-1])) ^ rcon(i / 4);
            else
                w[i] = w[i-4] ^ w[i-1];
        end

        round_keys = 1408'b0;
        for (r = 0; r < 11; r = r + 1)
            round_keys[r*128 +: 128] = {w[4*r], w[4*r+1], w[4*r+2], w[4*r+3]};
    end
endmodule