module aes128_pipeline #(
    parameter PIPELINED      = 1,
    parameter UNROLL         = 1,
    parameter INLINE_KEY_EXP = 1
) (
    input              clk,
    input              rst,
    input              start,
    input              mode,         // fixed to 1'b0 for encryption
    input      [127:0] data_in,
    input      [127:0] key_in,
    input              valid_in,
    output reg [127:0] data_out,
    output reg         valid_out,
    output reg         done
);

    // ------------------------------------------------------------
    // S-box (256 entries)
    // ------------------------------------------------------------
    function [7:0] sbox_f;
        input [7:0] a;
        reg [7:0] box [0:255];
        begin
            box[8'h00]=8'h63; box[8'h01]=8'h7c; box[8'h02]=8'h77; box[8'h03]=8'h7b;
            box[8'h04]=8'hf2; box[8'h05]=8'h6b; box[8'h06]=8'h6f; box[8'h07]=8'hc5;
            box[8'h08]=8'h30; box[8'h09]=8'h01; box[8'h0a]=8'h67; box[8'h0b]=8'h2b;
            box[8'h0c]=8'hfe; box[8'h0d]=8'hd7; box[8'h0e]=8'hab; box[8'h0f]=8'h76;
            box[8'h10]=8'hca; box[8'h11]=8'h82; box[8'h12]=8'hc9; box[8'h13]=8'h7d;
            box[8'h14]=8'hfa; box[8'h15]=8'h59; box[8'h16]=8'h47; box[8'h17]=8'hf0;
            box[8'h18]=8'had; box[8'h19]=8'hd4; box[8'h1a]=8'ha2; box[8'h1b]=8'haf;
            box[8'h1c]=8'h9c; box[8'h1d]=8'ha4; box[8'h1e]=8'h72; box[8'h1f]=8'hc0;
            box[8'h20]=8'hb7; box[8'h21]=8'hfd; box[8'h22]=8'h93; box[8'h23]=8'h26;
            box[8'h24]=8'h36; box[8'h25]=8'h3f; box[8'h26]=8'hf7; box[8'h27]=8'hcc;
            box[8'h28]=8'h34; box[8'h29]=8'ha5; box[8'h2a]=8'he5; box[8'h2b]=8'hf1;
            box[8'h2c]=8'h71; box[8'h2d]=8'hd8; box[8'h2e]=8'h31; box[8'h2f]=8'h15;
            box[8'h30]=8'h04; box[8'h31]=8'hc7; box[8'h32]=8'h23; box[8'h33]=8'hc3;
            box[8'h34]=8'h18; box[8'h35]=8'h96; box[8'h36]=8'h05; box[8'h37]=8'h9a;
            box[8'h38]=8'h07; box[8'h39]=8'h12; box[8'h3a]=8'h80; box[8'h3b]=8'he2;
            box[8'h3c]=8'heb; box[8'h3d]=8'h27; box[8'h3e]=8'hb2; box[8'h3f]=8'h75;
            box[8'h40]=8'h09; box[8'h41]=8'h83; box[8'h42]=8'h2c; box[8'h43]=8'h1a;
            box[8'h44]=8'h1b; box[8'h45]=8'h6e; box[8'h46]=8'h5a; box[8'h47]=8'ha0;
            box[8'h48]=8'h52; box[8'h49]=8'h3b; box[8'h4a]=8'hd6; box[8'h4b]=8'hb3;
            box[8'h4c]=8'h29; box[8'h4d]=8'he3; box[8'h4e]=8'h2f; box[8'h4f]=8'h84;
            box[8'h50]=8'h53; box[8'h51]=8'hd1; box[8'h52]=8'h00; box[8'h53]=8'hed;
            box[8'h54]=8'h20; box[8'h55]=8'hfc; box[8'h56]=8'hb1; box[8'h57]=8'h5b;
            box[8'h58]=8'h6a; box[8'h59]=8'hcb; box[8'h5a]=8'hbe; box[8'h5b]=8'h39;
            box[8'h5c]=8'h4a; box[8'h5d]=8'h4c; box[8'h5e]=8'h58; box[8'h5f]=8'hcf;
            box[8'h60]=8'hd0; box[8'h61]=8'hef; box[8'h62]=8'haa; box[8'h63]=8'hfb;
            box[8'h64]=8'h43; box[8'h65]=8'h4d; box[8'h66]=8'h33; box[8'h67]=8'h85;
            box[8'h68]=8'h45; box[8'h69]=8'hf9; box[8'h6a]=8'h02; box[8'h6b]=8'h7f;
            box[8'h6c]=8'h50; box[8'h6d]=8'h3c; box[8'h6e]=8'h9f; box[8'h6f]=8'ha8;
            box[8'h70]=8'h51; box[8'h71]=8'ha3; box[8'h72]=8'h40; box[8'h73]=8'h8f;
            box[8'h74]=8'h92; box[8'h75]=8'h9d; box[8'h76]=8'h38; box[8'h77]=8'hf5;
            box[8'h78]=8'hbc; box[8'h79]=8'hb6; box[8'h7a]=8'hda; box[8'h7b]=8'h21;
            box[8'h7c]=8'h10; box[8'h7d]=8'hff; box[8'h7e]=8'hf3; box[8'h7f]=8'hd2;
            box[8'h80]=8'hcd; box[8'h81]=8'h0c; box[8'h82]=8'h13; box[8'h83]=8'hec;
            box[8'h84]=8'h5f; box[8'h85]=8'h97; box[8'h86]=8'h44; box[8'h87]=8'h17;
            box[8'h88]=8'hc4; box[8'h89]=8'ha7; box[8'h8a]=8'h7e; box[8'h8b]=8'h3d;
            box[8'h8c]=8'h64; box[8'h8d]=8'h5d; box[8'h8e]=8'h19; box[8'h8f]=8'h73;
            box[8'h90]=8'h60; box[8'h91]=8'h81; box[8'h92]=8'h4f; box[8'h93]=8'hdc;
            box[8'h94]=8'h22; box[8'h95]=8'h2a; box[8'h96]=8'h90; box[8'h97]=8'h88;
            box[8'h98]=8'h46; box[8'h99]=8'hee; box[8'h9a]=8'hb8; box[8'h9b]=8'h14;
            box[8'h9c]=8'hde; box[8'h9d]=8'h5e; box[8'h9e]=8'h0b; box[8'h9f]=8'hdb;
            box[8'ha0]=8'he0; box[8'ha1]=8'h32; box[8'ha2]=8'h3a; box[8'ha3]=8'h0a;
            box[8'ha4]=8'h49; box[8'ha5]=8'h06; box[8'ha6]=8'h24; box[8'ha7]=8'h5c;
            box[8'ha8]=8'hc2; box[8'ha9]=8'hd3; box[8'haa]=8'hac; box[8'hab]=8'h62;
            box[8'hac]=8'h91; box[8'had]=8'h95; box[8'hae]=8'he4; box[8'haf]=8'h79;
            box[8'hb0]=8'he7; box[8'hb1]=8'hc8; box[8'hb2]=8'h37; box[8'hb3]=8'h6d;
            box[8'hb4]=8'h8d; box[8'hb5]=8'hd5; box[8'hb6]=8'h4e; box[8'hb7]=8'ha9;
            box[8'hb8]=8'h6c; box[8'hb9]=8'h56; box[8'hba]=8'hf4; box[8'hbb]=8'hea;
            box[8'hbc]=8'h65; box[8'hbd]=8'h7a; box[8'hbe]=8'hae; box[8'hbf]=8'h08;
            box[8'hc0]=8'hba; box[8'hc1]=8'h78; box[8'hc2]=8'h25; box[8'hc3]=8'h2e;
            box[8'hc4]=8'h1c; box[8'hc5]=8'ha6; box[8'hc6]=8'hb4; box[8'hc7]=8'hc6;
            box[8'hc8]=8'he8; box[8'hc9]=8'hdd; box[8'hca]=8'h74; box[8'hcb]=8'h1f;
            box[8'hcc]=8'h4b; box[8'hcd]=8'hbd; box[8'hce]=8'h8b; box[8'hcf]=8'h8a;
            box[8'hd0]=8'h70; box[8'hd1]=8'h3e; box[8'hd2]=8'hb5; box[8'hd3]=8'h66;
            box[8'hd4]=8'h48; box[8'hd5]=8'h03; box[8'hd6]=8'hf6; box[8'hd7]=8'h0e;
            box[8'hd8]=8'h61; box[8'hd9]=8'h35; box[8'hda]=8'h57; box[8'hdb]=8'hb9;
            box[8'hdc]=8'h86; box[8'hdd]=8'hc1; box[8'hde]=8'h1d; box[8'hdf]=8'h9e;
            box[8'he0]=8'he1; box[8'he1]=8'hf8; box[8'he2]=8'h98; box[8'he3]=8'h11;
            box[8'he4]=8'h69; box[8'he5]=8'hd9; box[8'he6]=8'h8e; box[8'he7]=8'h94;
            box[8'he8]=8'h9b; box[8'he9]=8'h1e; box[8'hea]=8'h87; box[8'heb]=8'he9;
            box[8'hec]=8'hce; box[8'hed]=8'h55; box[8'hee]=8'h28; box[8'hef]=8'hdf;
            box[8'hf0]=8'h8c; box[8'hf1]=8'ha1; box[8'hf2]=8'h89; box[8'hf3]=8'h0d;
            box[8'hf4]=8'hbf; box[8'hf5]=8'he6; box[8'hf6]=8'h42; box[8'hf7]=8'h68;
            box[8'hf8]=8'h41; box[8'hf9]=8'h99; box[8'hfa]=8'h2d; box[8'hfb]=8'h0f;
            box[8'hfc]=8'hb0; box[8'hfd]=8'h54; box[8'hfe]=8'hbb; box[8'hff]=8'h16;
            sbox_f = box[a];
        end
    endfunction

    // xtime for GF(2^8) mult by 2
    function [7:0] xtime;
        input [7:0] a;
        begin
            xtime = (a[7]) ? ((a << 1) ^ 8'h1b) : (a << 1);
        end
    endfunction

    function [7:0] gmul;
        input [7:0] a;
        input [7:0] b;
        reg [7:0] p, aa, bb;
        integer i;
        begin
            p = 8'h00;
            aa = a;
            bb = b;
            for (i = 0; i < 8; i = i + 1) begin
                if (bb[0])
                    p = p ^ aa;
                aa = xtime(aa);
                bb = bb >> 1;
            end
            gmul = p;
        end
    endfunction

    // SubBytes on 128-bit state (16 bytes)
    function [127:0] subbytes_f;
        input [127:0] st;
        integer i;
        reg [127:0] out;
        begin
            for (i = 0; i < 16; i = i + 1)
                out[i*8 +: 8] = sbox_f(st[i*8 +: 8]);
            subbytes_f = out;
        end
    endfunction

    // State byte layout: byte0 = st[127:120] is s[0][0], column-major like FIPS-197
    // We treat 128-bit vector as 16 bytes b0..b15 with b0 = MSB byte (st[127:120])
    // Standard AES state matrix (column-major):
    //   b0  b4  b8  b12
    //   b1  b5  b9  b13
    //   b2  b6  b10 b14
    //   b3  b7  b11 b15

    function [127:0] shiftrows_f;
        input [127:0] st;
        reg [7:0] b [0:15];
        reg [7:0] o [0:15];
        integer i;
        begin
            for (i = 0; i < 16; i = i + 1)
                b[i] = st[(15-i)*8 +: 8];

            // row0 no shift
            o[0]  = b[0];
            o[4]  = b[4];
            o[8]  = b[8];
            o[12] = b[12];
            // row1 shift left by1
            o[1]  = b[5];
            o[5]  = b[9];
            o[9]  = b[13];
            o[13] = b[1];
            // row2 shift left by2
            o[2]  = b[10];
            o[6]  = b[14];
            o[10] = b[2];
            o[14] = b[6];
            // row3 shift left by3
            o[3]  = b[15];
            o[7]  = b[3];
            o[11] = b[7];
            o[15] = b[11];

            for (i = 0; i < 16; i = i + 1)
                shiftrows_f[(15-i)*8 +: 8] = o[i];
        end
    endfunction

    function [127:0] mixcolumns_f;
        input [127:0] st;
        reg [7:0] b [0:15];
        reg [7:0] o [0:15];
        integer c;
        integer i;
        reg [7:0] s0,s1,s2,s3;
        begin
            for (i = 0; i < 16; i = i + 1)
                b[i] = st[(15-i)*8 +: 8];

            for (c = 0; c < 4; c = c + 1) begin
                s0 = b[c*4+0];
                s1 = b[c*4+1];
                s2 = b[c*4+2];
                s3 = b[c*4+3];
                o[c*4+0] = gmul(s0,8'h02) ^ gmul(s1,8'h03) ^ s2 ^ s3;
                o[c*4+1] = s0 ^ gmul(s1,8'h02) ^ gmul(s2,8'h03) ^ s3;
                o[c*4+2] = s0 ^ s1 ^ gmul(s2,8'h02) ^ gmul(s3,8'h03);
                o[c*4+3] = gmul(s0,8'h03) ^ s1 ^ s2 ^ gmul(s3,8'h02);
            end

            for (i = 0; i < 16; i = i + 1)
                mixcolumns_f[(15-i)*8 +: 8] = o[i];
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

    function [7:0] rcon_f;
        input [3:0] idx; // 1..10
        reg [7:0] r;
        integer k;
        begin
            r = 8'h01;
            for (k = 1; k < idx; k = k + 1)
                r = xtime(r);
            rcon_f = r;
        end
    endfunction

    // ------------------------------------------------------------
    // FSM
    // ------------------------------------------------------------
    localparam IDLE   = 2'd0;
    localparam RUN    = 2'd1;
    localparam DONE_S = 2'd2;

    reg [1:0]   state;
    reg [3:0]   round;      // current round number (1..10) being applied
    reg [127:0] cur_state;
    reg [127:0] cur_key;    // current round key (round0 = original key)

    always @(posedge clk) begin
        if (rst) begin
            state     <= IDLE;
            round     <= 4'd0;
            cur_state <= 128'd0;
            cur_key   <= 128'd0;
            data_out  <= 128'd0;
            valid_out <= 1'b0;
            done      <= 1'b0;
        end else begin
            valid_out <= 1'b0;
            done      <= 1'b0;

            case (state)
                IDLE: begin
                    if (start && valid_in) begin
                        // AddRoundKey with round0 key
                        cur_state <= data_in ^ key_in;
                        cur_key   <= key_in;
                        round     <= 4'd1;
                        state     <= RUN;
                    end
                end

                RUN: begin
                    reg [31:0] w0, w1, w2, w3;
                    reg [31:0] nw0, nw1, nw2, nw3;
                    reg [127:0] next_key;
                    reg [127:0] sb, sr, mc;

                    // Key expansion: derive next round key from cur_key
                    w0 = cur_key[127:96];
                    w1 = cur_key[95:64];
                    w2 = cur_key[63:32];
                    w3 = cur_key[31:0];

                    nw0 = w0 ^ subword_f(rotword_f(w3)) ^ {rcon_f(round), 24'h0};
                    nw1 = w1 ^ nw0;
                    nw2 = w2 ^ nw1;
                    nw3 = w3 ^ nw2;
                    next_key = {nw0, nw1, nw2, nw3};

                    sb = subbytes_f(cur_state);
                    sr = shiftrows_f(sb);

                    if (round == 4'd10) begin
                        // final round: no MixColumns
                        cur_state <= sr ^ next_key;
                        cur_key   <= next_key;
                        state     <= DONE_S;
                    end else begin
                        mc = mixcolumns_f(sr);
                        cur_state <= mc ^ next_key;
                        cur_key   <= next_key;
                        round     <= round + 4'd1;
                    end
                end

                DONE_S: begin
                    data_out  <= cur_state;
                    valid_out <= 1'b1;
                    done      <= 1'b1;
                    state     <= IDLE;
                end

                default: state <= IDLE;
            endcase
        end
    end

endmodule