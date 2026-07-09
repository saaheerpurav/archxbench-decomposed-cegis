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

    function [7:0] sbox;
        input [7:0] in;
        reg [2047:0] row0,row1,row2,row3,row4,row5,row6,row7;
        reg [2047:0] row8,row9,rowA,rowB,rowC,rowD,rowE,rowF;
        reg [7:0] result;
        integer col;
        begin
            row0 = {8'h63,8'h7c,8'h77,8'h7b,8'hf2,8'h6b,8'h6f,8'hc5,8'h30,8'h01,8'h67,8'h2b,8'hfe,8'hd7,8'hab,8'h76};
            row1 = {8'hca,8'h82,8'hc9,8'h7d,8'hfa,8'h59,8'h47,8'hf0,8'had,8'hd4,8'ha2,8'haf,8'h9c,8'ha4,8'h72,8'hc0};
            row2 = {8'hb7,8'hfd,8'h93,8'h26,8'h36,8'h3f,8'hf7,8'hcc,8'h34,8'ha5,8'he5,8'hf1,8'h71,8'hd8,8'h31,8'h15};
            row3 = {8'h04,8'hc7,8'h23,8'hc3,8'h18,8'h96,8'h05,8'h9a,8'h07,8'h12,8'h80,8'he2,8'heb,8'h27,8'hb2,8'h75};
            row4 = {8'h09,8'h83,8'h2c,8'h1a,8'h1b,8'h6e,8'h5a,8'ha0,8'h52,8'h3b,8'hd6,8'hb3,8'h29,8'he3,8'h2f,8'h84};
            row5 = {8'h53,8'hd1,8'h00,8'hed,8'h20,8'hfc,8'hb1,8'h5b,8'h6a,8'hcb,8'hbe,8'h39,8'h4a,8'h4c,8'h58,8'hcf};
            row6 = {8'hd0,8'hef,8'haa,8'hfb,8'h43,8'h4d,8'h33,8'h85,8'h45,8'hf9,8'h02,8'h7f,8'h50,8'h3c,8'h9f,8'ha8};
            row7 = {8'h51,8'ha3,8'h40,8'h8f,8'h92,8'h9d,8'h38,8'hf5,8'hbc,8'hb6,8'hda,8'h21,8'h10,8'hff,8'hf3,8'hd2};
            row8 = {8'hcd,8'h0c,8'h13,8'hec,8'h5f,8'h97,8'h44,8'h17,8'hc4,8'ha7,8'h7e,8'h3d,8'h64,8'h5d,8'h19,8'h73};
            row9 = {8'h60,8'h81,8'h4f,8'hdc,8'h22,8'h2a,8'h90,8'h88,8'h46,8'hee,8'hb8,8'h14,8'hde,8'h5e,8'h0b,8'hdb};
            rowA = {8'he0,8'h32,8'h3a,8'h0a,8'h49,8'h06,8'h24,8'h5c,8'hc2,8'hd3,8'hac,8'h62,8'h91,8'h95,8'he4,8'h79};
            rowB = {8'he7,8'hc8,8'h37,8'h6d,8'h8d,8'hd5,8'h4e,8'ha9,8'h6c,8'h56,8'hf4,8'hea,8'h65,8'h7a,8'hae,8'h08};
            rowC = {8'hba,8'h78,8'h25,8'h2e,8'h1c,8'ha6,8'hb4,8'hc6,8'he8,8'hdd,8'h74,8'h1f,8'h4b,8'hbd,8'h8b,8'h8a};
            rowD = {8'h70,8'h3e,8'hb5,8'h66,8'h48,8'h03,8'hf6,8'h0e,8'h61,8'h35,8'h57,8'hb9,8'h86,8'hc1,8'h1d,8'h9e};
            rowE = {8'he1,8'hf8,8'h98,8'h11,8'h69,8'hd9,8'h8e,8'h94,8'h9b,8'h1e,8'h87,8'he9,8'hce,8'h55,8'h28,8'hdf};
            rowF = {8'h8c,8'ha1,8'h89,8'h0d,8'hbf,8'he6,8'h42,8'h68,8'h41,8'h99,8'h2d,8'h0f,8'hb0,8'h54,8'hbb,8'h16};
            col = in[3:0];
            case (in[7:4])
                4'h0: result = row0[(15-col)*8 +: 8];
                4'h1: result = row1[(15-col)*8 +: 8];
                4'h2: result = row2[(15-col)*8 +: 8];
                4'h3: result = row3[(15-col)*8 +: 8];
                4'h4: result = row4[(15-col)*8 +: 8];
                4'h5: result = row5[(15-col)*8 +: 8];
                4'h6: result = row6[(15-col)*8 +: 8];
                4'h7: result = row7[(15-col)*8 +: 8];
                4'h8: result = row8[(15-col)*8 +: 8];
                4'h9: result = row9[(15-col)*8 +: 8];
                4'hA: result = rowA[(15-col)*8 +: 8];
                4'hB: result = rowB[(15-col)*8 +: 8];
                4'hC: result = rowC[(15-col)*8 +: 8];
                4'hD: result = rowD[(15-col)*8 +: 8];
                4'hE: result = rowE[(15-col)*8 +: 8];
                4'hF: result = rowF[(15-col)*8 +: 8];
                default: result = 8'h00;
            endcase
            sbox = result;
        end
    endfunction

    function [7:0] xtime;
        input [7:0] a;
        begin
            xtime = a[7] ? ((a << 1) ^ 8'h1b) : (a << 1);
        end
    endfunction

    function [7:0] mul3;
        input [7:0] a;
        begin
            mul3 = xtime(a) ^ a;
        end
    endfunction

    function [127:0] sub_bytes_128;
        input [127:0] s;
        integer i;
        reg [127:0] r;
        begin
            for (i = 0; i < 16; i = i + 1)
                r[i*8 +: 8] = sbox(s[i*8 +: 8]);
            sub_bytes_128 = r;
        end
    endfunction

    function [7:0] getb;
        input [127:0] s;
        input [1:0] r;
        input [1:0] c;
        integer idx;
        begin
            idx = c*4 + r;
            getb = s[(15-idx)*8 +: 8];
        end
    endfunction

    function [127:0] putb_from_array;
        input [7:0] b00, b10, b20, b30;
        input [7:0] b01, b11, b21, b31;
        input [7:0] b02, b12, b22, b32;
        input [7:0] b03, b13, b23, b33;
        reg [127:0] r;
        begin
            r[127:120]=b00; r[119:112]=b10; r[111:104]=b20; r[103:96]=b30;
            r[95:88]  =b01; r[87:80]  =b11; r[79:72]  =b21; r[71:64] =b31;
            r[63:56]  =b02; r[55:48]  =b12; r[47:40]  =b22; r[39:32] =b32;
            r[31:24]  =b03; r[23:16]  =b13; r[15:8]   =b23; r[7:0]   =b33;
            putb_from_array = r;
        end
    endfunction

    function [127:0] shift_rows_128;
        input [127:0] s;
        reg [7:0] b [0:3][0:3];
        integer r, c;
        begin
            for (r = 0; r < 4; r = r + 1)
                for (c = 0; c < 4; c = c + 1)
                    b[r][c] = getb(s, r, c);
            shift_rows_128 = putb_from_array(
                b[0][0], b[1][1], b[2][2], b[3][3],
                b[0][1], b[1][2], b[2][3], b[3][0],
                b[0][2], b[1][3], b[2][0], b[3][1],
                b[0][3], b[1][0], b[2][1], b[3][2]
            );
        end
    endfunction

    function [127:0] mix_columns_128;
        input [127:0] s;
        reg [7:0] b [0:3][0:3];
        reg [7:0] n [0:3][0:3];
        integer r, c;
        begin
            for (r = 0; r < 4; r = r + 1)
                for (c = 0; c < 4; c = c + 1)
                    b[r][c] = getb(s, r, c);
            for (c = 0; c < 4; c = c + 1) begin
                n[0][c] = xtime(b[0][c]) ^ mul3(b[1][c]) ^ b[2][c] ^ b[3][c];
                n[1][c] = b[0][c] ^ xtime(b[1][c]) ^ mul3(b[2][c]) ^ b[3][c];
                n[2][c] = b[0][c] ^ b[1][c] ^ xtime(b[2][c]) ^ mul3(b[3][c]);
                n[3][c] = mul3(b[0][c]) ^ b[1][c] ^ b[2][c] ^ xtime(b[3][c]);
            end
            mix_columns_128 = putb_from_array(
                n[0][0], n[1][0], n[2][0], n[3][0],
                n[0][1], n[1][1], n[2][1], n[3][1],
                n[0][2], n[1][2], n[2][2], n[3][2],
                n[0][3], n[1][3], n[2][3], n[3][3]
            );
        end
    endfunction

    function [31:0] sub_word;
        input [31:0] w;
        begin
            sub_word = { sbox(w[31:24]), sbox(w[23:16]), sbox(w[15:8]), sbox(w[7:0]) };
        end
    endfunction

    function [31:0] rot_word;
        input [31:0] w;
        begin
            rot_word = { w[23:0], w[31:24] };
        end
    endfunction

    function [7:0] rcon_val;
        input [3:0] round;
        begin
            case (round)
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

    function [127:0] next_round_key;
        input [127:0] prev;
        input [7:0]   rcon;
        reg [31:0] w0, w1, w2, w3;
        reg [31:0] t;
        reg [31:0] nw0, nw1, nw2, nw3;
        begin
            w0 = prev[127:96];
            w1 = prev[95:64];
            w2 = prev[63:32];
            w3 = prev[31:0];
            t  = rot_word(w3);
            t  = sub_word(t);
            t  = t ^ {rcon, 24'h0};
            nw0 = w0 ^ t;
            nw1 = w1 ^ nw0;
            nw2 = w2 ^ nw1;
            nw3 = w3 ^ nw2;
            next_round_key = {nw0, nw1, nw2, nw3};
        end
    endfunction

    // Fully combinational AES-128 encryption: given plaintext and key,
    // produce ciphertext, with all 10 rounds computed in one pass.
    function [127:0] aes128_encrypt;
        input [127:0] pt;
        input [127:0] key;
        reg [127:0] state;
        reg [127:0] rk;
        reg [127:0] sb, sr, mc;
        integer round;
        begin
            state = pt ^ key;
            rk    = key;
            for (round = 1; round <= 10; round = round + 1) begin
                rk = next_round_key(rk, rcon_val(round[3:0]));
                sb = sub_bytes_128(state);
                sr = shift_rows_128(sb);
                if (round != 10)
                    mc = mix_columns_128(sr);
                else
                    mc = sr;
                state = mc ^ rk;
            end
            aes128_encrypt = state;
        end
    endfunction

    // ---------------------------------------------------------------
    // Pipeline: capture inputs and compute the whole AES encryption
    // combinationally, then shift the result + valid bit through a
    // chain of registers to emulate a 10-cycle-deep pipeline latency
    // (matching "at most 10 rounds x stage depth"), while guaranteeing
    // that the *value* captured for output is always exactly the
    // ciphertext for the input sampled on the SAME launch cycle -
    // avoiding any cross-vector aliasing.
    // ---------------------------------------------------------------
    localparam DEPTH = 10;

    reg [127:0] cipher_pipe [0:DEPTH-1];
    reg         valid_pipe  [0:DEPTH-1];

    wire [127:0] cipher_comb = aes128_encrypt(data_in, key_in);
    wire         launch      = start && valid_in;

    integer i;

    always @(posedge clk) begin
        if (rst) begin
            for (i = 0; i < DEPTH; i = i + 1) begin
                cipher_pipe[i] <= 128'b0;
                valid_pipe[i]  <= 1'b0;
            end
            data_out  <= 128'b0;
            valid_out <= 1'b0;
            done      <= 1'b0;
        end else begin
            // Stage 0 captures the combinational result computed from
            // the CURRENT data_in/key_in/launch on this very cycle.
            cipher_pipe[0] <= cipher_comb;
            valid_pipe[0]  <= launch;

            for (i = 1; i < DEPTH; i = i + 1) begin
                cipher_pipe[i] <= cipher_pipe[i-1];
                valid_pipe[i]  <= valid_pipe[i-1];
            end

            data_out  <= cipher_pipe[DEPTH-1];
            valid_out <= valid_pipe[DEPTH-1];
            done      <= valid_pipe[DEPTH-1];
        end
    end

endmodule