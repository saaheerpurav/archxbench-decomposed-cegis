module aes128_pipeline #(
    parameter PIPELINED      = 1,
    parameter UNROLL         = 1,
    parameter INLINE_KEY_EXP = 1
) (
    input              clk,
    input              rst,
    input              start,
    input              mode,         // fixed to 1'b1 for decryption
    input      [127:0] data_in,
    input      [127:0] key_in,
    input              valid_in,
    output reg [127:0] data_out,
    output reg         valid_out,
    output reg         done
);

    // ===========================================================
    // GF(2^8) multiplication
    // ===========================================================
    function [7:0] gmul;
        input [7:0] a, b;
        reg [7:0] p, aa, bb;
        integer i;
        begin
            p = 8'h00; aa = a; bb = b;
            for (i = 0; i < 8; i = i + 1) begin
                if (bb[0]) p = p ^ aa;
                aa = (aa[7]) ? ((aa << 1) ^ 8'h1b) : (aa << 1);
                bb = bb >> 1;
            end
            gmul = p;
        end
    endfunction

    // Multiplicative inverse in GF(2^8) via brute force search
    function [7:0] gf_inv;
        input [7:0] a;
        integer i;
        reg [7:0] r;
        begin
            r = 8'h00;
            if (a != 8'h00) begin
                for (i = 0; i < 256; i = i + 1) begin
                    if (gmul(a, i[7:0]) == 8'h01) r = i[7:0];
                end
            end
            gf_inv = r;
        end
    endfunction

    function [7:0] rotl8;
        input [7:0] a;
        input [2:0] n;
        begin
            rotl8 = (a << n) | (a >> (8-n));
        end
    endfunction

    // Forward S-box: affine transform after GF inversion
    // sbox(a) = A * ginv(a) + 0x63 , A-matrix realized via rotl XORs
    function [7:0] sbox_f;
        input [7:0] a;
        reg [7:0] s;
        begin
            s = gf_inv(a);
            sbox_f = s ^ rotl8(s,1) ^ rotl8(s,2) ^ rotl8(s,3) ^ rotl8(s,4) ^ 8'h63;
        end
    endfunction

    // Inverse S-box: inverse affine transform then GF inverse
    // inv_sbox(a) = ginv( rotl(a,1) ^ rotl(a,3) ^ rotl(a,6) ^ 0x05 )
    function [7:0] inv_sbox_f;
        input [7:0] a;
        reg [7:0] t;
        begin
            t = rotl8(a,1) ^ rotl8(a,3) ^ rotl8(a,6) ^ 8'h05;
            inv_sbox_f = gf_inv(t);
        end
    endfunction

    // ===========================================================
    // Rcon values for key expansion (rounds 1..10)
    // ===========================================================
    function [7:0] rcon_f;
        input [3:0] idx;
        begin
            case(idx)
                4'd1: rcon_f = 8'h01;
                4'd2: rcon_f = 8'h02;
                4'd3: rcon_f = 8'h04;
                4'd4: rcon_f = 8'h08;
                4'd5: rcon_f = 8'h10;
                4'd6: rcon_f = 8'h20;
                4'd7: rcon_f = 8'h40;
                4'd8: rcon_f = 8'h80;
                4'd9: rcon_f = 8'h1b;
                4'd10: rcon_f = 8'h36;
                default: rcon_f = 8'h00;
            endcase
        end
    endfunction

    function [31:0] subword_f;
        input [31:0] w;
        begin
            subword_f = { sbox_f(w[31:24]), sbox_f(w[23:16]), sbox_f(w[15:8]), sbox_f(w[7:0]) };
        end
    endfunction

    function [31:0] rotword_f;
        input [31:0] w;
        begin
            rotword_f = { w[23:0], w[31:24] };
        end
    endfunction

    // Key expansion: prev is [w0 w1 w2 w3], rnd = round number (1..10)
    function [127:0] next_rk_f;
        input [127:0] prev;
        input [3:0]   rnd;
        reg [31:0] w0,w1,w2,w3;
        reg [31:0] t;
        begin
            w0 = prev[127:96];
            w1 = prev[95:64];
            w2 = prev[63:32];
            w3 = prev[31:0];
            t  = subword_f(rotword_f(w3)) ^ {rcon_f(rnd), 24'h0};
            w0 = w0 ^ t;
            w1 = w1 ^ w0;
            w2 = w2 ^ w1;
            w3 = w3 ^ w2;
            next_rk_f = {w0, w1, w2, w3};
        end
    endfunction

    // ===========================================================
    // AES State convention: COLUMN-MAJOR
    // data[127:120] = byte0 = s[0][0]
    // data[119:112] = byte1 = s[1][0]
    // data[111:104] = byte2 = s[2][0]
    // data[103:96 ] = byte3 = s[3][0]
    // data[95:88  ] = byte4 = s[0][1]  ... etc.
    // Column c occupies bytes {4c, 4c+1, 4c+2, 4c+3} = rows 0,1,2,3
    // ===========================================================

    function [127:0] inv_shiftrows_f;
        input [127:0] s;
        reg [7:0] b[0:15];
        reg [7:0] o[0:15];
        integer i;
        begin
            for (i = 0; i < 16; i = i + 1)
                b[i] = s[127-8*i -: 8];
            // row0 (bytes 0,4,8,12): no shift
            o[0]=b[0]; o[4]=b[4]; o[8]=b[8]; o[12]=b[12];
            // row1 (bytes 1,5,9,13): shift right by 1 -> take from col-1
            o[1]=b[13]; o[5]=b[1]; o[9]=b[5]; o[13]=b[9];
            // row2 (bytes 2,6,10,14): shift right by 2
            o[2]=b[10]; o[6]=b[14]; o[10]=b[2]; o[14]=b[6];
            // row3 (bytes 3,7,11,15): shift right by 3 (= left by1)
            o[3]=b[7]; o[7]=b[11]; o[11]=b[15]; o[15]=b[3];
            inv_shiftrows_f = { o[0],o[1],o[2],o[3], o[4],o[5],o[6],o[7],
                                 o[8],o[9],o[10],o[11], o[12],o[13],o[14],o[15] };
        end
    endfunction

    function [127:0] inv_subbytes_f;
        input [127:0] s;
        reg [7:0] b[0:15];
        integer i;
        begin
            for (i = 0; i < 16; i = i + 1)
                b[i] = inv_sbox_f(s[127-8*i -: 8]);
            inv_subbytes_f = { b[0],b[1],b[2],b[3], b[4],b[5],b[6],b[7],
                                b[8],b[9],b[10],b[11], b[12],b[13],b[14],b[15] };
        end
    endfunction

    function [127:0] addroundkey_f;
        input [127:0] s;
        input [127:0] k;
        begin
            addroundkey_f = s ^ k;
        end
    endfunction

    // InvMixColumns : per column c, bytes {4c+0,4c+1,4c+2,4c+3} = rows 0..3
    function [127:0] inv_mixcolumns_f;
        input [127:0] s;
        reg [7:0] b[0:15];
        reg [7:0] o[0:15];
        integer c;
        reg [7:0] s0,s1,s2,s3;
        begin
            for (c = 0; c < 16; c = c + 1)
                b[c] = s[127-8*c -: 8];
            for (c = 0; c < 4; c = c + 1) begin
                s0 = b[4*c+0];
                s1 = b[4*c+1];
                s2 = b[4*c+2];
                s3 = b[4*c+3];
                o[4*c+0] = gmul(s0,8'h0e) ^ gmul(s1,8'h0b) ^ gmul(s2,8'h0d) ^ gmul(s3,8'h09);
                o[4*c+1] = gmul(s0,8'h09) ^ gmul(s1,8'h0e) ^ gmul(s2,8'h0b) ^ gmul(s3,8'h0d);
                o[4*c+2] = gmul(s0,8'h0d) ^ gmul(s1,8'h09) ^ gmul(s2,8'h0e) ^ gmul(s3,8'h0b);
                o[4*c+3] = gmul(s0,8'h0b) ^ gmul(s1,8'h0d) ^ gmul(s2,8'h09) ^ gmul(s3,8'h0e);
            end
            inv_mixcolumns_f = { o[0],o[1],o[2],o[3], o[4],o[5],o[6],o[7],
                                  o[8],o[9],o[10],o[11], o[12],o[13],o[14],o[15] };
        end
    endfunction

    // ===========================================================
    // Pipeline: Stage0 = initial AddRoundKey(rk10)
    // Stages1..9 = full inverse round with InvMixColumns
    // Stage10 = final round (no InvMixColumns), AddRoundKey(rk0)
    // ===========================================================
    localparam NSTAGES = 11;

    reg [127:0] state_pipe [0:NSTAGES-1];
    reg [127:0] rk_pipe    [0:NSTAGES-1][0:10];
    reg         valid_pipe [0:NSTAGES-1];

    integer si, sj;

    // Full forward key schedule computed combinationally from key_in
    reg [127:0] rk_comb [0:10];
    integer kk;
    always @(*) begin
        rk_comb[0] = key_in;
        for (kk = 1; kk <= 10; kk = kk + 1) begin
            rk_comb[kk] = next_rk_f(rk_comb[kk-1], kk[3:0]);
        end
    end

    always @(posedge clk) begin
        if (rst) begin
            for (si = 0; si < NSTAGES; si = si + 1) begin
                state_pipe[si] <= 128'h0;
                valid_pipe[si] <= 1'b0;
                for (sj = 0; sj <= 10; sj = sj + 1)
                    rk_pipe[si][sj] <= 128'h0;
            end
            valid_out <= 1'b0;
            done      <= 1'b0;
            data_out  <= 128'h0;
        end else begin
            // Stage 0: initial AddRoundKey with rk[10]
            if (valid_in && start) begin
                state_pipe[0] <= addroundkey_f(data_in, rk_comb[10]);
                valid_pipe[0] <= 1'b1;
                for (sj = 0; sj <= 10; sj = sj + 1)
                    rk_pipe[0][sj] <= rk_comb[sj];
            end else begin
                valid_pipe[0] <= 1'b0;
            end

            // Stages 1..9: full inverse round
            for (si = 1; si <= 9; si = si + 1) begin
                state_pipe[si] <= inv_mixcolumns_f(
                                     addroundkey_f(
                                        inv_subbytes_f(
                                           inv_shiftrows_f(state_pipe[si-1])
                                        ),
                                        rk_pipe[si-1][10-si]
                                     )
                                   );
                valid_pipe[si] <= valid_pipe[si-1];
                for (sj = 0; sj <= 10; sj = sj + 1)
                    rk_pipe[si][sj] <= rk_pipe[si-1][sj];
            end

            // Stage 10: final round (no InvMixColumns), AddRoundKey(rk0)
            state_pipe[10] <= addroundkey_f(
                                 inv_subbytes_f(
                                    inv_shiftrows_f(state_pipe[9])
                                 ),
                                 rk_pipe[9][0]
                               );
            valid_pipe[10] <= valid_pipe[9];

            // Output
            data_out  <= state_pipe[10];
            valid_out <= valid_pipe[10];
            done      <= valid_pipe[10];
        end
    end

endmodule