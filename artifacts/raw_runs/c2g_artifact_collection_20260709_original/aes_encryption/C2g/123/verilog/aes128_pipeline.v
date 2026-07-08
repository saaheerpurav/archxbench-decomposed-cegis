`timescale 1ns/1ps

module aes128_pipeline #(
    parameter PIPELINED      = 1,
    parameter UNROLL         = 1,
    parameter INLINE_KEY_EXP = 1
) (
    input              clk,
    input              rst,
    input              start,
    input              mode,
    input      [127:0] data_in,
    input      [127:0] key_in,
    input              valid_in,
    output reg [127:0] data_out,
    output reg         valid_out,
    output reg         done
);

    reg done_d;

    function [7:0] xtime;
        input [7:0] b;
        begin
            xtime = {b[6:0], 1'b0} ^ (8'h1b & {8{b[7]}});
        end
    endfunction

    function [7:0] gf_mul;
        input [7:0] a;
        input [7:0] b;
        integer i;
        reg [7:0] aa, bb, p;
        begin
            aa = a;
            bb = b;
            p = 8'h00;
            for (i = 0; i < 8; i = i + 1) begin
                if (bb[0])
                    p = p ^ aa;
                aa = xtime(aa);
                bb = bb >> 1;
            end
            gf_mul = p;
        end
    endfunction

    function [7:0] gf_inv;
        input [7:0] a;
        reg [7:0] a2, a4, a8, a16, a32, a64, a128;
        begin
            if (a == 8'h00) begin
                gf_inv = 8'h00;
            end else begin
                a2   = gf_mul(a, a);
                a4   = gf_mul(a2, a2);
                a8   = gf_mul(a4, a4);
                a16  = gf_mul(a8, a8);
                a32  = gf_mul(a16, a16);
                a64  = gf_mul(a32, a32);
                a128 = gf_mul(a64, a64);
                gf_inv = gf_mul(gf_mul(gf_mul(gf_mul(gf_mul(gf_mul(a128, a64), a32), a16), a8), a4), a2);
            end
        end
    endfunction

    function [7:0] sbox;
        input [7:0] a;
        reg [7:0] x;
        reg [7:0] c;
        integer i;
        begin
            x = gf_inv(a);
            c = 8'h63;
            for (i = 0; i < 8; i = i + 1)
                sbox[i] = x[i] ^ x[(i+4)%8] ^ x[(i+5)%8] ^ x[(i+6)%8] ^ x[(i+7)%8] ^ c[i];
        end
    endfunction

    function [7:0] mul2;
        input [7:0] b;
        begin
            mul2 = xtime(b);
        end
    endfunction

    function [7:0] mul3;
        input [7:0] b;
        begin
            mul3 = xtime(b) ^ b;
        end
    endfunction

    function [31:0] sub_word;
        input [31:0] w;
        begin
            sub_word = {sbox(w[31:24]), sbox(w[23:16]), sbox(w[15:8]), sbox(w[7:0])};
        end
    endfunction

    function [31:0] rcon_word;
        input integer round;
        begin
            case (round)
                1:  rcon_word = 32'h01000000;
                2:  rcon_word = 32'h02000000;
                3:  rcon_word = 32'h04000000;
                4:  rcon_word = 32'h08000000;
                5:  rcon_word = 32'h10000000;
                6:  rcon_word = 32'h20000000;
                7:  rcon_word = 32'h40000000;
                8:  rcon_word = 32'h80000000;
                9:  rcon_word = 32'h1b000000;
                10: rcon_word = 32'h36000000;
                default: rcon_word = 32'h00000000;
            endcase
        end
    endfunction

    function [127:0] next_round_key;
        input [127:0] key;
        input integer round;
        reg [31:0] w0, w1, w2, w3, t;
        begin
            w0 = key[127:96];
            w1 = key[95:64];
            w2 = key[63:32];
            w3 = key[31:0];

            t  = sub_word({w3[23:0], w3[31:24]}) ^ rcon_word(round);
            w0 = w0 ^ t;
            w1 = w1 ^ w0;
            w2 = w2 ^ w1;
            w3 = w3 ^ w2;

            next_round_key = {w0, w1, w2, w3};
        end
    endfunction

    function [7:0] get_byte;
        input [127:0] s;
        input integer idx;
        begin
            get_byte = s[127 - idx*8 -: 8];
        end
    endfunction

    function [127:0] sub_bytes;
        input [127:0] s;
        integer j;
        begin
            for (j = 0; j < 16; j = j + 1)
                sub_bytes[127 - j*8 -: 8] = sbox(get_byte(s, j));
        end
    endfunction

    function [127:0] shift_rows;
        input [127:0] s;
        begin
            shift_rows = {
                get_byte(s, 0),  get_byte(s, 5),  get_byte(s, 10), get_byte(s, 15),
                get_byte(s, 4),  get_byte(s, 9),  get_byte(s, 14), get_byte(s, 3),
                get_byte(s, 8),  get_byte(s, 13), get_byte(s, 2),  get_byte(s, 7),
                get_byte(s, 12), get_byte(s, 1),  get_byte(s, 6),  get_byte(s, 11)
            };
        end
    endfunction

    function [127:0] mix_columns;
        input [127:0] s;
        integer col;
        reg [7:0] a0, a1, a2, a3;
        begin
            for (col = 0; col < 4; col = col + 1) begin
                a0 = get_byte(s, col*4 + 0);
                a1 = get_byte(s, col*4 + 1);
                a2 = get_byte(s, col*4 + 2);
                a3 = get_byte(s, col*4 + 3);

                mix_columns[127 - (col*4 + 0)*8 -: 8] = mul2(a0) ^ mul3(a1) ^ a2 ^ a3;
                mix_columns[127 - (col*4 + 1)*8 -: 8] = a0 ^ mul2(a1) ^ mul3(a2) ^ a3;
                mix_columns[127 - (col*4 + 2)*8 -: 8] = a0 ^ a1 ^ mul2(a2) ^ mul3(a3);
                mix_columns[127 - (col*4 + 3)*8 -: 8] = mul3(a0) ^ a1 ^ a2 ^ mul2(a3);
            end
        end
    endfunction

    function [127:0] aes_encrypt;
        input [127:0] pt;
        input [127:0] key;
        integer r;
        reg [127:0] st;
        reg [127:0] rk;
        begin
            rk = key;
            st = pt ^ rk;

            for (r = 1; r <= 9; r = r + 1) begin
                rk = next_round_key(rk, r);
                st = mix_columns(shift_rows(sub_bytes(st))) ^ rk;
            end

            rk = next_round_key(rk, 10);
            aes_encrypt = shift_rows(sub_bytes(st)) ^ rk;
        end
    endfunction

    always @(posedge clk) begin
        if (rst) begin
            data_out  <= 128'h0;
            valid_out <= 1'b0;
            done      <= 1'b0;
            done_d    <= 1'b0;
        end else begin
            valid_out <= done_d;
            done      <= done_d;
            done_d    <= 1'b0;

            if (start & valid_in & ~mode) begin
                data_out <= aes_encrypt(data_in, key_in);
                done_d   <= 1'b1;
            end
        end
    end

endmodule