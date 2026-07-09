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

  reg [7:0] SBOX    [0:255];
  reg [7:0] INVSBOX [0:255];
  integer ii;

  initial begin
    SBOX[8'h00]=8'h63; SBOX[8'h01]=8'h7c; SBOX[8'h02]=8'h77; SBOX[8'h03]=8'h7b;
    SBOX[8'h04]=8'hf2; SBOX[8'h05]=8'h6b; SBOX[8'h06]=8'h6f; SBOX[8'h07]=8'hc5;
    SBOX[8'h08]=8'h30; SBOX[8'h09]=8'h01; SBOX[8'h0a]=8'h67; SBOX[8'h0b]=8'h2b;
    SBOX[8'h0c]=8'hfe; SBOX[8'h0d]=8'hd7; SBOX[8'h0e]=8'hab; SBOX[8'h0f]=8'h76;
    SBOX[8'h10]=8'hca; SBOX[8'h11]=8'h82; SBOX[8'h12]=8'hc9; SBOX[8'h13]=8'h7d;
    SBOX[8'h14]=8'hfa; SBOX[8'h15]=8'h59; SBOX[8'h16]=8'h47; SBOX[8'h17]=8'hf0;
    SBOX[8'h18]=8'had; SBOX[8'h19]=8'hd4; SBOX[8'h1a]=8'ha2; SBOX[8'h1b]=8'haf;
    SBOX[8'h1c]=8'h9c; SBOX[8'h1d]=8'ha4; SBOX[8'h1e]=8'h72; SBOX[8'h1f]=8'hc0;
    SBOX[8'h20]=8'hb7; SBOX[8'h21]=8'hfd; SBOX[8'h22]=8'h93; SBOX[8'h23]=8'h26;
    SBOX[8'h24]=8'h36; SBOX[8'h25]=8'h3f; SBOX[8'h26]=8'hf7; SBOX[8'h27]=8'hcc;
    SBOX[8'h28]=8'h34; SBOX[8'h29]=8'ha5; SBOX[8'h2a]=8'he5; SBOX[8'h2b]=8'hf1;
    SBOX[8'h2c]=8'h71; SBOX[8'h2d]=8'hd8; SBOX[8'h2e]=8'h31; SBOX[8'h2f]=8'h15;
    SBOX[8'h30]=8'h04; SBOX[8'h31]=8'hc7; SBOX[8'h32]=8'h23; SBOX[8'h33]=8'hc3;
    SBOX[8'h34]=8'h18; SBOX[8'h35]=8'h96; SBOX[8'h36]=8'h05; SBOX[8'h37]=8'h9a;
    SBOX[8'h38]=8'h07; SBOX[8'h39]=8'h12; SBOX[8'h3a]=8'h80; SBOX[8'h3b]=8'he2;
    SBOX[8'h3c]=8'heb; SBOX[8'h3d]=8'h27; SBOX[8'h3e]=8'hb2; SBOX[8'h3f]=8'h75;
    SBOX[8'h40]=8'h09; SBOX[8'h41]=8'h83; SBOX[8'h42]=8'h2c; SBOX[8'h43]=8'h1a;
    SBOX[8'h44]=8'h1b; SBOX[8'h45]=8'h6e; SBOX[8'h46]=8'h5a; SBOX[8'h47]=8'ha0;
    SBOX[8'h48]=8'h52; SBOX[8'h49]=8'h3b; SBOX[8'h4a]=8'hd6; SBOX[8'h4b]=8'hb3;
    SBOX[8'h4c]=8'h29; SBOX[8'h4d]=8'he3; SBOX[8'h4e]=8'h2f; SBOX[8'h4f]=8'h84;
    SBOX[8'h50]=8'h53; SBOX[8'h51]=8'hd1; SBOX[8'h52]=8'h00; SBOX[8'h53]=8'hed;
    SBOX[8'h54]=8'h20; SBOX[8'h55]=8'hfc; SBOX[8'h56]=8'hb1; SBOX[8'h57]=8'h5b;
    SBOX[8'h58]=8'h6a; SBOX[8'h59]=8'hcb; SBOX[8'h5a]=8'hbe; SBOX[8'h5b]=8'h39;
    SBOX[8'h5c]=8'h4a; SBOX[8'h5d]=8'h4c; SBOX[8'h5e]=8'h58; SBOX[8'h5f]=8'hcf;
    SBOX[8'h60]=8'hd0; SBOX[8'h61]=8'hef; SBOX[8'h62]=8'haa; SBOX[8'h63]=8'hfb;
    SBOX[8'h64]=8'h43; SBOX[8'h65]=8'h4d; SBOX[8'h66]=8'h33; SBOX[8'h67]=8'h85;
    SBOX[8'h68]=8'h45; SBOX[8'h69]=8'hf9; SBOX[8'h6a]=8'h02; SBOX[8'h6b]=8'h7f;
    SBOX[8'h6c]=8'h50; SBOX[8'h6d]=8'h3c; SBOX[8'h6e]=8'h9f; SBOX[8'h6f]=8'ha8;
    SBOX[8'h70]=8'h51; SBOX[8'h71]=8'ha3; SBOX[8'h72]=8'h40; SBOX[8'h73]=8'h8f;
    SBOX[8'h74]=8'h92; SBOX[8'h75]=8'h9d; SBOX[8'h76]=8'h38; SBOX[8'h77]=8'hf5;
    SBOX[8'h78]=8'hbc; SBOX[8'h79]=8'hb6; SBOX[8'h7a]=8'hda; SBOX[8'h7b]=8'h21;
    SBOX[8'h7c]=8'h10; SBOX[8'h7d]=8'hff; SBOX[8'h7e]=8'hf3; SBOX[8'h7f]=8'hd2;
    SBOX[8'h80]=8'hcd; SBOX[8'h81]=8'h0c; SBOX[8'h82]=8'h13; SBOX[8'h83]=8'hec;
    SBOX[8'h84]=8'h5f; SBOX[8'h85]=8'h97; SBOX[8'h86]=8'h44; SBOX[8'h87]=8'h17;
    SBOX[8'h88]=8'hc4; SBOX[8'h89]=8'ha7; SBOX[8'h8a]=8'h7e; SBOX[8'h8b]=8'h3d;
    SBOX[8'h8c]=8'h64; SBOX[8'h8d]=8'h5d; SBOX[8'h8e]=8'h19; SBOX[8'h8f]=8'h73;
    SBOX[8'h90]=8'h60; SBOX[8'h91]=8'h81; SBOX[8'h92]=8'h4f; SBOX[8'h93]=8'hdc;
    SBOX[8'h94]=8'h22; SBOX[8'h95]=8'h2a; SBOX[8'h96]=8'h90; SBOX[8'h97]=8'h88;
    SBOX[8'h98]=8'h46; SBOX[8'h99]=8'hee; SBOX[8'h9a]=8'hb8; SBOX[8'h9b]=8'h14;
    SBOX[8'h9c]=8'hde; SBOX[8'h9d]=8'h5e; SBOX[8'h9e]=8'h0b; SBOX[8'h9f]=8'hdb;
    SBOX[8'ha0]=8'he0; SBOX[8'ha1]=8'h32; SBOX[8'ha2]=8'h3a; SBOX[8'ha3]=8'h0a;
    SBOX[8'ha4]=8'h49; SBOX[8'ha5]=8'h06; SBOX[8'ha6]=8'h24; SBOX[8'ha7]=8'h5c;
    SBOX[8'ha8]=8'hc2; SBOX[8'ha9]=8'hd3; SBOX[8'haa]=8'hac; SBOX[8'hab]=8'h62;
    SBOX[8'hac]=8'h91; SBOX[8'had]=8'h95; SBOX[8'hae]=8'he4; SBOX[8'haf]=8'h79;
    SBOX[8'hb0]=8'he7; SBOX[8'hb1]=8'hc8; SBOX[8'hb2]=8'h37; SBOX[8'hb3]=8'h6d;
    SBOX[8'hb4]=8'h8d; SBOX[8'hb5]=8'hd5; SBOX[8'hb6]=8'h4e; SBOX[8'hb7]=8'ha9;
    SBOX[8'hb8]=8'h6c; SBOX[8'hb9]=8'h56; SBOX[8'hba]=8'hf4; SBOX[8'hbb]=8'hea;
    SBOX[8'hbc]=8'h65; SBOX[8'hbd]=8'h7a; SBOX[8'hbe]=8'hae; SBOX[8'hbf]=8'h08;
    SBOX[8'hc0]=8'hba; SBOX[8'hc1]=8'h78; SBOX[8'hc2]=8'h25; SBOX[8'hc3]=8'h2e;
    SBOX[8'hc4]=8'h1c; SBOX[8'hc5]=8'ha6; SBOX[8'hc6]=8'hb4; SBOX[8'hc7]=8'hc6;
    SBOX[8'hc8]=8'he8; SBOX[8'hc9]=8'hdd; SBOX[8'hca]=8'h74; SBOX[8'hcb]=8'h1f;
    SBOX[8'hcc]=8'h4b; SBOX[8'hcd]=8'hbd; SBOX[8'hce]=8'h8b; SBOX[8'hcf]=8'h8a;
    SBOX[8'hd0]=8'h70; SBOX[8'hd1]=8'h3e; SBOX[8'hd2]=8'hb5; SBOX[8'hd3]=8'h66;
    SBOX[8'hd4]=8'h48; SBOX[8'hd5]=8'h03; SBOX[8'hd6]=8'hf6; SBOX[8'hd7]=8'h0e;
    SBOX[8'hd8]=8'h61; SBOX[8'hd9]=8'h35; SBOX[8'hda]=8'h57; SBOX[8'hdb]=8'hb9;
    SBOX[8'hdc]=8'h86; SBOX[8'hdd]=8'hc1; SBOX[8'hde]=8'h1d; SBOX[8'hdf]=8'h9e;
    SBOX[8'he0]=8'he1; SBOX[8'he1]=8'hf8; SBOX[8'he2]=8'h98; SBOX[8'he3]=8'h11;
    SBOX[8'he4]=8'h69; SBOX[8'he5]=8'hd9; SBOX[8'he6]=8'h8e; SBOX[8'he7]=8'h94;
    SBOX[8'he8]=8'h9b; SBOX[8'he9]=8'h1e; SBOX[8'hea]=8'h87; SBOX[8'heb]=8'he9;
    SBOX[8'hec]=8'hce; SBOX[8'hed]=8'h55; SBOX[8'hee]=8'h28; SBOX[8'hef]=8'hdf;
    SBOX[8'hf0]=8'h8c; SBOX[8'hf1]=8'ha1; SBOX[8'hf2]=8'h89; SBOX[8'hf3]=8'h0d;
    SBOX[8'hf4]=8'hbf; SBOX[8'hf5]=8'he6; SBOX[8'hf6]=8'h42; SBOX[8'hf7]=8'h68;
    SBOX[8'hf8]=8'h41; SBOX[8'hf9]=8'h99; SBOX[8'hfa]=8'h2d; SBOX[8'hfb]=8'h0f;
    SBOX[8'hfc]=8'hb0; SBOX[8'hfd]=8'h54; SBOX[8'hfe]=8'hbb; SBOX[8'hff]=8'h16;
    for (ii = 0; ii < 256; ii = ii + 1)
      INVSBOX[SBOX[ii]] = ii[7:0];
  end

  function [7:0] xtime;
    input [7:0] a;
    begin xtime = (a[7]) ? ((a<<1)^8'h1b) : (a<<1); end
  endfunction

  function [7:0] gmul;
    input [7:0] a, b;
    reg [7:0] p, aa, bb;
    integer k;
    begin
      p=0; aa=a; bb=b;
      for (k=0;k<8;k=k+1) begin
        if (bb[0]) p = p ^ aa;
        aa = xtime(aa);
        bb = bb >> 1;
      end
      gmul = p;
    end
  endfunction

  function [31:0] subword;
    input [31:0] w;
    begin subword = {SBOX[w[31:24]],SBOX[w[23:16]],SBOX[w[15:8]],SBOX[w[7:0]]}; end
  endfunction

  function [31:0] rotword;
    input [31:0] w;
    begin rotword = {w[23:0], w[31:24]}; end
  endfunction

  function [7:0] rcon_f;
    input [3:0] r;
    reg [7:0] rc;
    integer k;
    begin
      rc = 8'h01;
      for (k=1;k<r;k=k+1) rc = xtime(rc);
      rcon_f = rc;
    end
  endfunction

  function [1407:0] expand_key_words;
    input [127:0] key;
    reg [31:0] w [0:43];
    integer i;
    reg [31:0] temp;
    reg [1407:0] packed_w;
    begin
      w[0]=key[127:96]; w[1]=key[95:64]; w[2]=key[63:32]; w[3]=key[31:0];
      for (i=4;i<44;i=i+1) begin
        temp = w[i-1];
        if ((i%4)==0) temp = subword(rotword(temp)) ^ {rcon_f(i/4),24'h0};
        w[i] = w[i-4] ^ temp;
      end
      packed_w = {1408{1'b0}};
      for (i=0;i<44;i=i+1) packed_w[1407 - i*32 -: 32] = w[i];
      expand_key_words = packed_w;
    end
  endfunction

  function [127:0] get_rk;
    input [1407:0] packed_w;
    input [3:0] r;
    reg [31:0] w0,w1,w2,w3;
    integer base;
    begin
      base = r*4;
      w0 = packed_w[1407-(base+0)*32 -: 32];
      w1 = packed_w[1407-(base+1)*32 -: 32];
      w2 = packed_w[1407-(base+2)*32 -: 32];
      w3 = packed_w[1407-(base+3)*32 -: 32];
      get_rk = {w0,w1,w2,w3};
    end
  endfunction

  function [127:0] inv_shift_rows;
    input [127:0] s_in;
    reg [7:0] b [0:15];
    reg [7:0] o [0:15];
    integer c;
    begin
      for (c=0;c<16;c=c+1) b[c] = s_in[127-c*8 -: 8];
      o[0]=b[0];  o[4]=b[4];  o[8]=b[8];   o[12]=b[12];
      o[1]=b[13]; o[5]=b[1];  o[9]=b[5];   o[13]=b[9];
      o[2]=b[10]; o[6]=b[14]; o[10]=b[2];  o[14]=b[6];
      o[3]=b[7];  o[7]=b[11]; o[11]=b[15]; o[15]=b[3];
      inv_shift_rows = {o[0],o[1],o[2],o[3],o[4],o[5],o[6],o[7],
                         o[8],o[9],o[10],o[11],o[12],o[13],o[14],o[15]};
    end
  endfunction

  function [127:0] inv_sub_bytes;
    input [127:0] s_in;
    reg [7:0] b [0:15];
    integer c;
    begin
      for (c=0;c<16;c=c+1) b[c] = INVSBOX[s_in[127-c*8 -: 8]];
      inv_sub_bytes = {b[0],b[1],b[2],b[3],b[4],b[5],b[6],b[7],
                        b[8],b[9],b[10],b[11],b[12],b[13],b[14],b[15]};
    end
  endfunction

  function [127:0] add_round_key;
    input [127:0] s_in;
    input [127:0] k_in;
    begin add_round_key = s_in ^ k_in; end
  endfunction

  function [127:0] inv_mix_columns;
    input [127:0] s_in;
    reg [7:0] b [0:15];
    reg [7:0] o [0:15];
    integer c;
    reg [7:0] a0,a1,a2,a3;
    begin
      for (c=0;c<16;c=c+1) b[c] = s_in[127-c*8 -: 8];
      for (c=0;c<4;c=c+1) begin
        a0=b[4*c+0]; a1=b[4*c+1]; a2=b[4*c+2]; a3=b[4*c+3];
        o[4*c+0] = gmul(a0,8'h0e)^gmul(a1,8'h0b)^gmul(a2,8'h0d)^gmul(a3,8'h09);
        o[4*c+1] = gmul(a0,8'h09)^gmul(a1,8'h0e)^gmul(a2,8'h0b)^gmul(a3,8'h0d);
        o[4*c+2] = gmul(a0,8'h0d)^gmul(a1,8'h09)^gmul(a2,8'h0e)^gmul(a3,8'h0b);
        o[4*c+3] = gmul(a0,8'h0b)^gmul(a1,8'h0d)^gmul(a2,8'h09)^gmul(a3,8'h0e);
      end
      inv_mix_columns = {o[0],o[1],o[2],o[3],o[4],o[5],o[6],o[7],
                          o[8],o[9],o[10],o[11],o[12],o[13],o[14],o[15]};
    end
  endfunction

  localparam NSTAGES = 10;

  reg [127:0]  state_pipe [0:NSTAGES];
  reg          valid_pipe [0:NSTAGES];
  reg [1407:0] key_pipe   [0:NSTAGES];
  integer si;

  wire [1407:0] new_key_words = expand_key_words(key_in);
  wire [127:0]  rk10_new      = get_rk(new_key_words, 4'd10);
  wire [127:0]  init_state    = add_round_key(data_in, rk10_new);

  wire [127:0] sr_stage  [1:NSTAGES];
  wire [127:0] sb_stage  [1:NSTAGES];
  wire [127:0] ark_stage [1:NSTAGES];
  wire [127:0] mix_stage [1:NSTAGES];
  wire [127:0] rk_stage  [1:NSTAGES];

  genvar g;
  generate
    for (g=1; g<=NSTAGES; g=g+1) begin : stage_gen
      assign rk_stage[g]  = get_rk(key_pipe[g-1], (10-g));
      assign sr_stage[g]  = inv_shift_rows(state_pipe[g-1]);
      assign sb_stage[g]  = inv_sub_bytes(sr_stage[g]);
      assign ark_stage[g] = add_round_key(sb_stage[g], rk_stage[g]);
      assign mix_stage[g] = (g==NSTAGES) ? ark_stage[g] : inv_mix_columns(ark_stage[g]);
    end
  endgenerate

  always @(posedge clk) begin
    if (rst) begin
      for (si=0; si<=NSTAGES; si=si+1) begin
        state_pipe[si] <= 128'b0;
        valid_pipe[si] <= 1'b0;
        key_pipe[si]   <= 1408'b0;
      end
      valid_out <= 1'b0;
      done      <= 1'b0;
      data_out  <= 128'b0;
    end
    else begin
      if (start && valid_in) begin
        state_pipe[0] <= init_state;
        key_pipe[0]   <= new_key_words;
        valid_pipe[0] <= 1'b1;
      end
      else valid_pipe[0] <= 1'b0;

      for (si=1; si<=NSTAGES; si=si+1) begin
        state_pipe[si] <= mix_stage[si];
        key_pipe[si]   <= key_pipe[si-1];
        valid_pipe[si] <= valid_pipe[si-1];
      end

      data_out  <= state_pipe[NSTAGES];
      valid_out <= valid_pipe[NSTAGES];
      done      <= valid_pipe[NSTAGES];
    end
  end

endmodule