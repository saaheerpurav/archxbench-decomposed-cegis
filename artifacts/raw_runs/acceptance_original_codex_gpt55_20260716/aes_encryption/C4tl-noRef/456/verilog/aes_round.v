`timescale 1ns/1ps

module aes_round #(
    parameter FINAL_ROUND = 0
) (
    input  [127:0] state_in,
    input  [127:0] round_key,
    output [127:0] state_out
);

    reg [127:0] subbed;
    reg [127:0] shifted;
    reg [127:0] mixed;
    integer i;

    always @* begin
        for (i = 0; i < 16; i = i + 1)
            subbed[127 - 8*i -: 8] = aes_sbox(state_in[127 - 8*i -: 8]);
    end

    always @* begin
        shifted[127:120] = subbed[127:120];
        shifted[119:112] = subbed[ 87: 80];
        shifted[111:104] = subbed[ 47: 40];
        shifted[103: 96] = subbed[  7:  0];

        shifted[ 95: 88] = subbed[ 95: 88];
        shifted[ 87: 80] = subbed[ 55: 48];
        shifted[ 79: 72] = subbed[ 15:  8];
        shifted[ 71: 64] = subbed[103: 96];

        shifted[ 63: 56] = subbed[ 63: 56];
        shifted[ 55: 48] = subbed[ 23: 16];
        shifted[ 47: 40] = subbed[111:104];
        shifted[ 39: 32] = subbed[ 71: 64];

        shifted[ 31: 24] = subbed[ 31: 24];
        shifted[ 23: 16] = subbed[119:112];
        shifted[ 15:  8] = subbed[ 79: 72];
        shifted[  7:  0] = subbed[ 39: 32];
    end

    always @* begin
        mixed[127: 96] = mix_column(shifted[127: 96]);
        mixed[ 95: 64] = mix_column(shifted[ 95: 64]);
        mixed[ 63: 32] = mix_column(shifted[ 63: 32]);
        mixed[ 31:  0] = mix_column(shifted[ 31:  0]);
    end

    assign state_out = ((FINAL_ROUND != 0) ? shifted : mixed) ^ round_key;

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
        reg [7:0] s0, s1, s2, s3;
        begin
            s0 = col[31:24];
            s1 = col[23:16];
            s2 = col[15: 8];
            s3 = col[ 7: 0];

            mix_column = {
                mul2(s0) ^ mul3(s1) ^ s2       ^ s3,
                s0       ^ mul2(s1) ^ mul3(s2) ^ s3,
                s0       ^ s1       ^ mul2(s2) ^ mul3(s3),
                mul3(s0) ^ s1       ^ s2       ^ mul2(s3)
            };
        end
    endfunction

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
                aa = xtime(aa);
                bb = bb >> 1;
            end
            gf_mul = p;
        end
    endfunction

    function [7:0] gf_inv;
        input [7:0] x;
        reg [7:0] result;
        reg [7:0] base;
        integer e;
        begin
            if (x == 8'h00) begin
                gf_inv = 8'h00;
            end else begin
                result = 8'h01;
                base   = x;
                for (e = 0; e < 8; e = e + 1) begin
                    if (8'd254[e])
                        result = gf_mul(result, base);
                    base = gf_mul(base, base);
                end
                gf_inv = result;
            end
        end
    endfunction

    function [7:0] aes_sbox;
        input [7:0] x;
        reg [7:0] inv;
        reg [7:0] y;
        integer b;
        begin
            inv = gf_inv(x);
            for (b = 0; b < 8; b = b + 1)
                y[b] = inv[b] ^ inv[(b + 4) & 7] ^ inv[(b + 5) & 7] ^
                       inv[(b + 6) & 7] ^ inv[(b + 7) & 7] ^ 8'h63[b];
            aes_sbox = y;
        end
    endfunction

endmodule