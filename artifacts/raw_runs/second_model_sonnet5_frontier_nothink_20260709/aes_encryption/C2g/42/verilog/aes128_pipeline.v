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

  // ---------------------------------------------------------------
  // S-box (256 entries)
  // ---------------------------------------------------------------
  function [7:0] sbox;
    input [7:0] in;
    reg [7:0] tbl [0:255];
    begin
      tbl[8'h00]=8'h63; tbl[8'h01]=8'h7c; tbl[8'h02]=8'h77; tbl[8'h03]=8'h7b;
      tbl[8'h04]=8'hf2; tbl[8'h05]=8'h6b; tbl[8'h06]=8'h6f; tbl[8'h07]=8'hc5;
      tbl[8'h08]=8'h30; tbl[8'h09]=8'h01; tbl[8'h0a]=8'h67; tbl[8'h0b]=8'h2b;
      tbl[8'h0c]=8'hfe; tbl[8'h0d]=8'hd7; tbl[8'h0e]=8'hab; tbl[8'h0f]=8'h76;
      tbl[8'h10]=8'hca; tbl[8'h11]=8'h82; tbl[8'h12]=8'hc9; tbl[8'h13]=8'h7d;
      tbl[8'h14]=8'hfa; tbl[8'h15]=8'h59; tbl[8'h16]=8'h47; tbl[8'h17]=8'hf0;
      tbl[8'h18]=8'had; tbl[8'h19]=8'hd4; tbl[8'h1a]=8'ha2; tbl[8'h1b]=8'haf;
      tbl[8'h1c]=8'h9c; tbl[8'h1d]=8'ha4; tbl[8'h1e]=8'h72; tbl[8'h1f]=8'hc0;
      tbl[8'h20]=8'hb7; tbl[8'h21]=8'hfd; tbl[8'h22]=8'h93; tbl[8'h23]=8'h26;
      tbl[8'h24]=8'h36; tbl[8'h25]=8'h3f; tbl[8'h26]=8'hf7; tbl[8'h27]=8'hcc;
      tbl[8'h28]=8'h34; tbl[8'h29]=8'ha5; tbl[8'h2a]=8'he5; tbl[8'h2b]=8'hf1;
      tbl[8'h2c]=8'h71; tbl[8'h2d]=8'hd8; tbl[8'h2e]=8'h31; tbl[8'h2f]=8'h15;
      tbl[8'h30]=8'h04; tbl[8'h31]=8'hc7; tbl[8'h32]=8'h23; tbl[8'h33]=8'hc3;
      tbl[8'h34]=8'h18; tbl[8'h35]=8'h96; tbl[8'h36]=8'h05; tbl[8'h37]=8'h9a;
      tbl[8'h38]=8'h07; tbl[8'h39]=8'h12; tbl[8'h3a]=8'h80; tbl[8'h3b]=8'he2;
      tbl[8'h3c]=8'heb; tbl[8'h3d]=8'h27; tbl[8'h3e]=8'hb2; tbl[8'h3f]=8'h75;
      tbl[8'h40]=8'h09; tbl[8'h41]=8'h83; tbl[8'h42]=8'h2c; tbl[8'h43]=8'h1a;
      tbl[8'h44]=8'h1b; tbl[8'h45]=8'h6e; tbl[8'h46]=8'h5a; tbl[8'h47]=8'ha0;
      tbl[8'h48]=8'h52; tbl[8'h49]=8'h3b; tbl[8'h4a]=8'hd6; tbl[8'h4b]=8'hb3;
      tbl[8'h4c]=8'h29; tbl[8'h4d]=8'he3; tbl[8'h4e]=8'h2f; tbl[8'h4f]=8'h84;
      tbl[8'h50]=8'h53; tbl[8'h51]=8'hd1; tbl[8'h52]=8'h00; tbl[8'h53]=8'hed;
      tbl[8'h54]=8'h20; tbl[8'h55]=8'hfc; tbl[8'h56]=8'hb1; tbl[8'h57]=8'h5b;
      tbl[8'h58]=8'h6a; tbl[8'h59]=8'hcb; tbl[8'h5a]=8'hbe; tbl[8'h5b]=8'h39;
      tbl[8'h5c]=8'h4a; tbl[8'h5d]=8'h4c; tbl[8'h5e]=8'h58; tbl[8'h5f]=8'hcf;
      tbl[8'h60]=8'hd0; tbl[8'h61]=8'hef; tbl[8'h62]=8'haa; tbl[8'h63]=8'hfb;
      tbl[8'h64]=8'h43; tbl[8'h65]=8'h4d; tbl[8'h66]=8'h33; tbl[8'h67]=8'h85;
      tbl[8'h68]=8'h45; tbl[8'h69]=8'hf9; tbl[8'h6a]=8'h02; tbl[8'h6b]=8'h7f;
      tbl[8'h6c]=8'h50; tbl[8'h6d]=8'h3c; tbl[8'h6e]=8'h9f; tbl[8'h6f]=8'ha8;
      tbl[8'h70]=8'h51; tbl[8'h71]=8'ha3; tbl[8'h72]=8'h40; tbl[8'h73]=8'h8f;
      tbl[8'h74]=8'h92; tbl[8'h75]=8'h9d; tbl[8'h76]=8'h38; tbl[8'h77]=8'hf5;
      tbl[8'h78]=8'hbc; tbl[8'h79]=8'hb6; tbl[8'h7a]=8'hda; tbl[8'h7b]=8'h21;
      tbl[8'h7c]=8'h10; tbl[8'h7d]=8'hff; tbl[8'h7e]=8'hf3; tbl[8'h7f]=8'hd2;
      tbl[8'h80]=8'hcd; tbl[8'h81]=8'h0c; tbl[8'h82]=8'h13; tbl[8'h83]=8'hec;
      tbl[8'h84]=8'h5f; tbl[8'h85]=8'h97; tbl[8'h86]=8'h44; tbl[8'h87]=8'h17;
      tbl[8'h88]=8'hc4; tbl[8'h89]=8'ha7; tbl[8'h8a]=8'h7e; tbl[8'h8b]=8'h3d;
      tbl[8'h8c]=8'h64; tbl[8'h8d]=8'h5d; tbl[8'h8e]=8'h19; tbl[8'h8f]=8'h73;
      tbl[8'h90]=8'h60; tbl[8'h91]=8'h81; tbl[8'h92]=8'h4f; tbl[8'h93]=8'hdc;
      tbl[8'h94]=8'h22; tbl[8'h95]=8'h2a; tbl[8'h96]=8'h90; tbl[8'h97]=8'h88;
      tbl[8'h98]=8'h46; tbl[8'h99]=8'hee; tbl[8'h9a]=8'hb8; tbl[8'h9b]=8'h14;
      tbl[8'h9c]=8'hde; tbl[8'h9d]=8'h5e; tbl[8'h9e]=8'h0b; tbl[8'h9f]=8'hdb;
      tbl[8'ha0]=8'he0; tbl[8'ha1]=8'h32; tbl[8'ha2]=8'h3a; tbl[8'ha3]=8'h0a;
      tbl[8'ha4]=8'h49; tbl[8'ha5]=8'h06; tbl[8'ha6]=8'h24; tbl[8'ha7]=8'h5c;
      tbl[8'ha8]=8'hc2; tbl[8'ha9]=8'hd3; tbl[8'haa]=8'hac; tbl[8'hab]=8'h62;
      tbl[8'hac]=8'h91; tbl[8'had]=8'h95; tbl[8'hae]=8'he4; tbl[8'haf]=8'h79;
      tbl[8'hb0]=8'he7; tbl[8'hb1]=8'hc8; tbl[8'hb2]=8'h37; tbl[8'hb3]=8'h6d;
      tbl[8'hb4]=8'h8d; tbl[8'hb5]=8'hd5; tbl[8'hb6]=8'h4e; tbl[8'hb7]=8'ha9;
      tbl[8'hb8]=8'h6c; tbl[8'hb9]=8'h56; tbl[8'hba]=8'hf4; tbl[8'hbb]=8'hea;
      tbl[8'hbc]=8'h65; tbl[8'hbd]=8'h7a; tbl[8'hbe]=8'hae; tbl[8'hbf]=8'h08;
      tbl[8'hc0]=8'hba; tbl[8'hc1]=8'h78; tbl[8'hc2]=8'h25; tbl[8'hc3]=8'h2e;
      tbl[8'hc4]=8'h1c; tbl[8'hc5]=8'ha6; tbl[8'hc6]=8'hb4; tbl[8'hc7]=8'hc6;
      tbl[8'hc8]=8'he8; tbl[8'hc9]=8'hdd; tbl[8'hca]=8'h74; tbl[8'hcb]=8'h1f;
      tbl[8'hcc]=8'h4b; tbl[8'hcd]=8'hbd; tbl[8'hce]=8'h8b; tbl[8'hcf]=8'h8a;
      tbl[8'hd0]=8'h70; tbl[8'hd1]=8'h3e; tbl[8'hd2]=8'hb5; tbl[8'hd3]=8'h66;
      tbl[8'hd4]=8'h48; tbl[8'hd5]=8'h03; tbl[8'hd6]=8'hf6; tbl[8'hd7]=8'h0e;
      tbl[8'hd8]=8'h61; tbl[8'hd9]=8'h35; tbl[8'hda]=8'h57; tbl[8'hdb]=8'hb9;
      tbl[8'hdc]=8'h86; tbl[8'hdd]=8'hc1; tbl[8'hde]=8'h1d; tbl[8'hdf]=8'h9e;
      tbl[8'he0]=8'he1; tbl[8'he1]=8'hf8; tbl[8'he2]=8'h98; tbl[8'he3]=8'h11;
      tbl[8'he4]=8'h69; tbl[8'he5]=8'hd9; tbl[8'he6]=8'h8e; tbl[8'he7]=8'h94;
      tbl[8'he8]=8'h9b; tbl[8'he9]=8'h1e; tbl[8'hea]=8'h87; tbl[8'heb]=8'he9;
      tbl[8'hec]=8'hce; tbl[8'hed]=8'h55; tbl[8'hee]=8'h28; tbl[8'hef]=8'hdf;
      tbl[8'hf0]=8'h8c; tbl[8'hf1]=8'ha1; tbl[8'hf2]=8'h89; tbl[8'hf3]=8'h0d;
      tbl[8'hf4]=8'hbf; tbl[8'hf5]=8'he6; tbl[8'hf6]=8'h42; tbl[8'hf7]=8'h68;
      tbl[8'hf8]=8'h41; tbl[8'hf9]=8'h99; tbl[8'hfa]=8'h2d; tbl[8'hfb]=8'h0f;
      tbl[8'hfc]=8'hb0; tbl[8'hfd]=8'h54; tbl[8'hfe]=8'hbb; tbl[8'hff]=8'h16;
      sbox = tbl[in];
    end
  endfunction

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

  // Byte i (0..15), byte 0 = MSB of the 128-bit word (st[127:120])
  function [7:0] get_byte;
    input [127:0] st;
    input [3:0]   i;
    begin
      get_byte = st[(15-i)*8 +: 8];
    end
  endfunction

  // SubBytes on 128-bit word
  function [127:0] sub_bytes128;
    input [127:0] st;
    integer i;
    reg [127:0] res;
    begin
      for (i = 0; i < 16; i = i + 1)
        res[(15-i)*8 +: 8] = sbox(get_byte(st, i));
      sub_bytes128 = res;
    end
  endfunction

  // State: byte b (0..15), column-major: s[r][c] = byte(c*4+r), byte0=MSB
  // ShiftRows: row r shifted left by r
  function [127:0] shift_rows;
    input [127:0] st;
    reg [7:0] s [0:15];
    reg [7:0] o [0:15];
    integer c;
    reg [127:0] res;
    begin
      for (c = 0; c < 16; c = c + 1)
        s[c] = get_byte(st, c);
      o[0]  = s[0];  o[4]  = s[4];  o[8]  = s[8];  o[12] = s[12];
      o[1]  = s[5];  o[5]  = s[9];  o[9]  = s[13]; o[13] = s[1];
      o[2]  = s[10]; o[6]  = s[14]; o[10] = s[2];  o[14] = s[6];
      o[3]  = s[15]; o[7]  = s[3];  o[11] = s[7];  o[15] = s[11];
      for (c = 0; c < 16; c = c + 1)
        res[(15-c)*8 +: 8] = o[c];
      shift_rows = res;
    end
  endfunction

  function [127:0] mix_columns;
    input [127:0] st;
    reg [7:0] s [0:15];
    reg [7:0] o [0:15];
    integer c;
    reg [7:0] a0, a1, a2, a3;
    reg [127:0] res;
    begin
      for (c = 0; c < 16; c = c + 1)
        s[c] = get_byte(st, c);
      for (c = 0; c < 4; c = c + 1) begin
        a0 = s[c*4+0];
        a1 = s[c*4+1];
        a2 = s[c*4+2];
        a3 = s[c*4+3];
        o[c*4+0] = gmul(a0,8'h02) ^ gmul(a1,8'h03) ^ a2 ^ a3;
        o[c*4+1] = a0 ^ gmul(a1,8'h02) ^ gmul(a2,8'h03) ^ a3;
        o[c*4+2] = a0 ^ a1 ^ gmul(a2,8'h02) ^ gmul(a3,8'h03);
        o[c*4+3] = gmul(a0,8'h03) ^ a1 ^ a2 ^ gmul(a3,8'h02);
      end
      for (c = 0; c < 16; c = c + 1)
        res[(15-c)*8 +: 8] = o[c];
      mix_columns = res;
    end
  endfunction

  function [31:0] rot_word;
    input [31:0] w;
    begin
      rot_word = {w[23:0], w[31:24]};
    end
  endfunction

  function [31:0] sub_word;
    input [31:0] w;
    begin
      sub_word = {sbox(w[31:24]), sbox(w[23:16]), sbox(w[15:8]), sbox(w[7:0])};
    end
  endfunction

  function [7:0] rcon;
    input [3:0] idx; // round number 1..10
    reg [7:0] rc;
    begin
      case (idx)
        4'd1: rc = 8'h01;
        4'd2: rc = 8'h02;
        4'd3: rc = 8'h04;
        4'd4: rc = 8'h08;
        4'd5: rc = 8'h10;
        4'd6: rc = 8'h20;
        4'd7: rc = 8'h40;
        4'd8: rc = 8'h80;
        4'd9: rc = 8'h1b;
        4'd10: rc = 8'h36;
        default: rc = 8'h00;
      endcase
      rcon = rc;
    end
  endfunction

  // Given previous 128-bit round key and round number(1..10)
  // produce next 128-bit round key.
  function [127:0] next_round_key;
    input [127:0] prev;
    input [3:0]   rnum;
    reg [31:0] w0, w1, w2, w3;
    reg [31:0] t;
    reg [31:0] nw0, nw1, nw2, nw3;
    begin
      w0 = prev[127:96];
      w1 = prev[95:64];
      w2 = prev[63:32];
      w3 = prev[31:0];
      t  = sub_word(rot_word(w3)) ^ {rcon(rnum), 24'h0};
      nw0 = w0 ^ t;
      nw1 = w1 ^ nw0;
      nw2 = w2 ^ nw1;
      nw3 = w3 ^ nw2;
      next_round_key = {nw0, nw1, nw2, nw3};
    end
  endfunction

  // ---------------------------------------------------------------
  // FSM
  // ---------------------------------------------------------------
  localparam ST_IDLE   = 2'd0;
  localparam ST_ROUND  = 2'd1;
  localparam ST_DONE   = 2'd2;

  reg [1:0]   state;
  reg [3:0]   round_cnt;   // 1..10
  reg [127:0] cur_state;
  reg [127:0] cur_key;

  reg [127:0] rk_next;
  reg [127:0] sb, sr, mc;

  always @(posedge clk) begin
    if (rst) begin
      state     <= ST_IDLE;
      round_cnt <= 4'd0;
      cur_state <= 128'd0;
      cur_key   <= 128'd0;
      data_out  <= 128'd0;
      valid_out <= 1'b0;
      done      <= 1'b0;
    end else begin
      valid_out <= 1'b0;
      done      <= 1'b0;

      case (state)
        ST_IDLE: begin
          if (start && valid_in) begin
            cur_state <= data_in ^ key_in;
            cur_key   <= key_in;
            round_cnt <= 4'd1;
            state     <= ST_ROUND;
          end
        end

        ST_ROUND: begin
          rk_next = next_round_key(cur_key, round_cnt);
          sb = sub_bytes128(cur_state);
          sr = shift_rows(sb);

          if (round_cnt == 4'd10) begin
            cur_state <= sr ^ rk_next;
            cur_key   <= rk_next;
            state     <= ST_DONE;
          end else begin
            mc = mix_columns(sr);
            cur_state <= mc ^ rk_next;
            cur_key   <= rk_next;
            round_cnt <= round_cnt + 4'd1;
          end
        end

        ST_DONE: begin
          data_out  <= cur_state;
          valid_out <= 1'b1;
          done      <= 1'b1;
          state     <= ST_IDLE;
        end

        default: state <= ST_IDLE;
      endcase
    end
  end

endmodule