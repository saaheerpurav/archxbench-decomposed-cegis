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

  reg [7:0] sbox  [0:255];
  reg [7:0] isbox [0:255];
  integer   init_i;

  initial begin
    sbox[8'h00]=8'h63; sbox[8'h01]=8'h7c; sbox[8'h02]=8'h77; sbox[8'h03]=8'h7b;
    sbox[8'h04]=8'hf2; sbox[8'h05]=8'h6b; sbox[8'h06]=8'h6f; sbox[8'h07]=8'hc5;
    sbox[8'h08]=8'h30; sbox[8'h09]=8'h01; sbox[8'h0a]=8'h67; sbox[8'h0b]=8'h2b;
    sbox[8'h0c]=8'hfe; sbox[8'h0d]=8'hd7; sbox[8'h0e]=8'hab; sbox[8'h0f]=8'h76;
    sbox[8'h10]=8'hca; sbox[8'h11]=8'h82; sbox[8'h12]=8'hc9; sbox[8'h13]=8'h7d;
    sbox[8'h14]=8'hfa; sbox[8'h15]=8'h59; sbox[8'h16]=8'h47; sbox[8'h17]=8'hf0;
    sbox[8'h18]=8'had; sbox[8'h19]=8'hd4; sbox[8'h1a]=8'ha2; sbox[8'h1b]=8'haf;
    sbox[8'h1c]=8'h9c; sbox[8'h1d]=8'ha4; sbox[8'h1e]=8'h72; sbox[8'h1f]=8'hc0;
    sbox[8'h20]=8'hb7; sbox[8'h21]=8'hfd; sbox[8'h22]=8'h93; sbox[8'h23]=8'h26;
    sbox[8'h24]=8'h36; sbox[8'h25]=8'h3f; sbox[8'h26]=8'hf7; sbox[8'h27]=8'hcc;
    sbox[8'h28]=8'h34; sbox[8'h29]=8'ha5; sbox[8'h2a]=8'he5; sbox[8'h2b]=8'hf1;
    sbox[8'h2c]=8'h71; sbox[8'h2d]=8'hd8; sbox[8'h2e]=8'h31; sbox[8'h2f]=8'h15;
    sbox[8'h30]=8'h04; sbox[8'h31]=8'hc7; sbox[8'h32]=8'h23; sbox[8'h33]=8'hc3;
    sbox[8'h34]=8'h18; sbox[8'h35]=8'h96; sbox[8'h36]=8'h05; sbox[8'h37]=8'h9a;
    sbox[8'h38]=8'h07; sbox[8'h39]=8'h12; sbox[8'h3a]=8'h80; sbox[8'h3b]=8'he2;
    sbox[8'h3c]=8'heb; sbox[8'h3d]=8'h27; sbox[8'h3e]=8'hb2; sbox[8'h3f]=8'h75;
    sbox[8'h40]=8'h09; sbox[8'h41]=8'h83; sbox[8'h42]=8'h2c; sbox[8'h43]=8'h1a;
    sbox[8'h44]=8'h1b; sbox[8'h45]=8'h6e; sbox[8'h46]=8'h5a; sbox[8'h47]=8'ha0;
    sbox[8'h48]=8'h52; sbox[8'h49]=8'h3b; sbox[8'h4a]=8'hd6; sbox[8'h4b]=8'hb3;
    sbox[8'h4c]=8'h29; sbox[8'h4d]=8'he3; sbox[8'h4e]=8'h2f; sbox[8'h4f]=8'h84;
    sbox[8'h50]=8'h53; sbox[8'h51]=8'hd1; sbox[8'h52]=8'h00; sbox[8'h53]=8'hed;
    sbox[8'h54]=8'h20; sbox[8'h55]=8'hfc; sbox[8'h56]=8'hb1; sbox[8'h57]=8'h5b;
    sbox[8'h58]=8'h6a; sbox[8'h59]=8'hcb; sbox[8'h5a]=8'hbe; sbox[8'h5b]=8'h39;
    sbox[8'h5c]=8'h4a; sbox[8'h5d]=8'h4c; sbox[8'h5e]=8'h58; sbox[8'h5f]=8'hcf;
    sbox[8'h60]=8'hd0; sbox[8'h61]=8'hef; sbox[8'h62]=8'haa; sbox[8'h63]=8'hfb;
    sbox[8'h64]=8'h43; sbox[8'h65]=8'h4d; sbox[8'h66]=8'h33; sbox[8'h67]=8'h85;
    sbox[8'h68]=8'h45; sbox[8'h69]=8'hf9; sbox[8'h6a]=8'h02; sbox[8'h6b]=8'h7f;
    sbox[8'h6c]=8'h50; sbox[8'h6d]=8'h3c; sbox[8'h6e]=8'h9f; sbox[8'h6f]=8'ha8;
    sbox[8'h70]=8'h51; sbox[8'h71]=8'ha3; sbox[8'h72]=8'h40; sbox[8'h73]=8'h8f;
    sbox[8'h74]=8'h92; sbox[8'h75]=8'h9d; sbox[8'h76]=8'h38; sbox[8'h77]=8'hf5;
    sbox[8'h78]=8'hbc; sbox[8'h79]=8'hb6; sbox[8'h7a]=8'hda; sbox[8'h7b]=8'h21;
    sbox[8'h7c]=8'h10; sbox[8'h7d]=8'hff; sbox[8'h7e]=8'hf3; sbox[8'h7f]=8'hd2;
    sbox[8'h80]=8'hcd; sbox[8'h81]=8'h0c; sbox[8'h82]=8'h13; sbox[8'h83]=8'hec;
    sbox[8'h84]=8'h5f; sbox[8'h85]=8'h97; sbox[8'h86]=8'h44; sbox[8'h87]=8'h17;
    sbox[8'h88]=8'hc4; sbox[8'h89]=8'ha7; sbox[8'h8a]=8'h7e; sbox[8'h8b]=8'h3d;
    sbox[8'h8c]=8'h64; sbox[8'h8d]=8'h5d; sbox[8'h8e]=8'h19; sbox[8'h8f]=8'h73;
    sbox[8'h90]=8'h60; sbox[8'h91]=8'h81; sbox[8'h92]=8'h4f; sbox[8'h93]=8'hdc;
    sbox[8'h94]=8'h22; sbox[8'h95]=8'h2a; sbox[8'h96]=8'h90; sbox[8'h97]=8'h88;
    sbox[8'h98]=8'h46; sbox[8'h99]=8'hee; sbox[8'h9a]=8'hb8; sbox[8'h9b]=8'h14;
    sbox[8'h9c]=8'hde; sbox[8'h9d]=8'h5e; sbox[8'h9e]=8'h0b; sbox[8'h9f]=8'hdb;
    sbox[8'ha0]=8'he0; sbox[8'ha1]=8'h32; sbox[8'ha2]=8'h3a; sbox[8'ha3]=8'h0a;
    sbox[8'ha4]=8'h49; sbox[8'ha5]=8'h06; sbox[8'ha6]=8'h24; sbox[8'ha7]=8'h5c;
    sbox[8'ha8]=8'hc2; sbox[8'ha9]=8'hd3; sbox[8'haa]=8'hac; sbox[8'hab]=8'h62;
    sbox[8'hac]=8'h91; sbox[8'had]=8'h95; sbox[8'hae]=8'he4; sbox[8'haf]=8'h79;
    sbox[8'hb0]=8'he7; sbox[8'hb1]=8'hc8; sbox[8'hb2]=8'h37; sbox[8'hb3]=8'h6d;
    sbox[8'hb4]=8'h8d; sbox[8'hb5]=8'hd5; sbox[8'hb6]=8'h4e; sbox[8'hb7]=8'ha9;
    sbox[8'hb8]=8'h6c; sbox[8'hb9]=8'h56; sbox[8'hba]=8'hf4; sbox[8'hbb]=8'hea;
    sbox[8'hbc]=8'h65; sbox[8'hbd]=8'h7a; sbox[8'hbe]=8'hae; sbox[8'hbf]=8'h08;
    sbox[8'hc0]=8'hba; sbox[8'hc1]=8'h78; sbox[8'hc2]=8'h25; sbox[8'hc3]=8'h2e;
    sbox[8'hc4]=8'h1c; sbox[8'hc5]=8'ha6; sbox[8'hc6]=8'hb4; sbox[8'hc7]=8'hc6;
    sbox[8'hc8]=8'he8; sbox[8'hc9]=8'hdd; sbox[8'hca]=8'h74; sbox[8'hcb]=8'h1f;
    sbox[8'hcc]=8'h4b; sbox[8'hcd]=8'hbd; sbox[8'hce]=8'h8b; sbox[8'hcf]=8'h8a;
    sbox[8'hd0]=8'h70; sbox[8'hd1]=8'h3e; sbox[8'hd2]=8'hb5; sbox[8'hd3]=8'h66;
    sbox[8'hd4]=8'h48; sbox[8'hd5]=8'h03; sbox[8'hd6]=8'hf6; sbox[8'hd7]=8'h0e;
    sbox[8'hd8]=8'h61; sbox[8'hd9]=8'h35; sbox[8'hda]=8'h57; sbox[8'hdb]=8'hb9;
    sbox[8'hdc]=8'h86; sbox[8'hdd]=8'hc1; sbox[8'hde]=8'h1d; sbox[8'hdf]=8'h9e;
    sbox[8'he0]=8'he1; sbox[8'he1]=8'hf8; sbox[8'he2]=8'h98; sbox[8'he3]=8'h11;
    sbox[8'he4]=8'h69; sbox[8'he5]=8'hd9; sbox[8'he6]=8'h8e; sbox[8'he7]=8'h94;
    sbox[8'he8]=8'h9b; sbox[8'he9]=8'h1e; sbox[8'hea]=8'h87; sbox[8'heb]=8'he9;
    sbox[8'hec]=8'hce; sbox[8'hed]=8'h55; sbox[8'hee]=8'h28; sbox[8'hef]=8'hdf;
    sbox[8'hf0]=8'h8c; sbox[8'hf1]=8'ha1; sbox[8'hf2]=8'h89; sbox[8'hf3]=8'h0d;
    sbox[8'hf4]=8'hbf; sbox[8'hf5]=8'he6; sbox[8'hf6]=8'h42; sbox[8'hf7]=8'h68;
    sbox[8'hf8]=8'h41; sbox[8'hf9]=8'h99; sbox[8'hfa]=8'h2d; sbox[8'hfb]=8'h0f;
    sbox[8'hfc]=8'hb0; sbox[8'hfd]=8'h54; sbox[8'hfe]=8'hbb; sbox[8'hff]=8'h16;

    for (init_i = 0; init_i < 256; init_i = init_i + 1) begin
      isbox[sbox[init_i]] = init_i[7:0];
    end
  end

  // =================================================================
  // GF(2^8) helpers
  // =================================================================
  function [7:0] gf_mul(input [7:0] a, input [7:0] b);
    reg [7:0] p, aa, bb;
    integer i;
    begin
      p = 8'h00; aa = a; bb = b;
      for (i = 0; i < 8; i = i + 1) begin
        if (bb[0]) p = p ^ aa;
        aa = (aa[7]) ? ((aa << 1) ^ 8'h1b) : (aa << 1);
        bb = bb >> 1;
      end
      gf_mul = p;
    end
  endfunction

  function [7:0] xtime(input [7:0] a);
    xtime = (a[7]) ? ((a << 1) ^ 8'h1b) : (a << 1);
  endfunction

  // =================================================================
  // Key expansion (forward AES-128) -> 11 round keys
  // =================================================================
  function [31:0] subword(input [31:0] w);
    subword = {sbox[w[31:24]], sbox[w[23:16]], sbox[w[15:8]], sbox[w[7:0]]};
  endfunction

  function [31:0] rotword(input [31:0] w);
    rotword = {w[23:0], w[31:24]};
  endfunction

  function [7:0] rcon_f(input integer idx);
    reg [7:0] r;
    integer k;
    begin
      r = 8'h01;
      for (k = 1; k < idx; k = k + 1) r = xtime(r);
      rcon_f = r;
    end
  endfunction

  function [1407:0] expand_key(input [127:0] key);
    reg [31:0] w [0:43];
    integer i;
    reg [31:0] temp;
    reg [1407:0] result;
    begin
      w[0] = key[127:96];
      w[1] = key[95:64];
      w[2] = key[63:32];
      w[3] = key[31:0];
      for (i = 4; i < 44; i = i + 1) begin
        temp = w[i-1];
        if (i % 4 == 0)
          temp = subword(rotword(temp)) ^ {rcon_f(i/4), 24'h0};
        w[i] = w[i-4] ^ temp;
      end
      for (i = 0; i < 11; i = i + 1) begin
        result[1407 - i*128 -: 128] = {w[i*4], w[i*4+1], w[i*4+2], w[i*4+3]};
      end
      expand_key = result;
    end
  endfunction

  function [127:0] get_rk(input [1407:0] rks, input integer round);
    get_rk = rks[1407 - round*128 -: 128];
  endfunction

  // =================================================================
  // State transforms
  // =================================================================
  function [127:0] inv_shift_rows(input [127:0] s);
    reg [7:0] b [0:15];
    reg [7:0] o [0:15];
    integer c;
    begin
      for (c = 0; c < 16; c = c + 1) b[c] = s[127 - c*8 -: 8];
      for (c = 0; c < 4; c = c + 1) begin
        o[c*4+0] = b[(((c+0)%4))*4+0];
        o[c*4+1] = b[(((c-1+4)%4))*4+1];
        o[c*4+2] = b[(((c-2+4)%4))*4+2];
        o[c*4+3] = b[(((c-3+4)%4))*4+3];
      end
      inv_shift_rows = {o[0],o[1],o[2],o[3],o[4],o[5],o[6],o[7],
                         o[8],o[9],o[10],o[11],o[12],o[13],o[14],o[15]};
    end
  endfunction

  function [127:0] inv_sub_bytes(input [127:0] s);
    integer i;
    reg [7:0] b [0:15];
    begin
      for (i = 0; i < 16; i = i + 1)
        b[i] = isbox[s[127-i*8 -: 8]];
      inv_sub_bytes = {b[0],b[1],b[2],b[3],b[4],b[5],b[6],b[7],
                        b[8],b[9],b[10],b[11],b[12],b[13],b[14],b[15]};
    end
  endfunction

  function [127:0] add_round_key(input [127:0] s, input [127:0] k);
    add_round_key = s ^ k;
  endfunction

  function [127:0] inv_mix_columns(input [127:0] s);
    reg [7:0] b [0:15];
    reg [7:0] o [0:15];
    integer c;
    reg [7:0] a0,a1,a2,a3;
    begin
      for (c = 0; c < 16; c = c + 1) b[c] = s[127 - c*8 -: 8];
      for (c = 0; c < 4; c = c + 1) begin
        a0 = b[c*4+0]; a1 = b[c*4+1]; a2 = b[c*4+2]; a3 = b[c*4+3];
        o[c*4+0] = gf_mul(a0,8'h0e) ^ gf_mul(a1,8'h0b) ^ gf_mul(a2,8'h0d) ^ gf_mul(a3,8'h09);
        o[c*4+1] = gf_mul(a0,8'h09) ^ gf_mul(a1,8'h0e) ^ gf_mul(a2,8'h0b) ^ gf_mul(a3,8'h0d);
        o[c*4+2] = gf_mul(a0,8'h0d) ^ gf_mul(a1,8'h09) ^ gf_mul(a2,8'h0e) ^ gf_mul(a3,8'h0b);
        o[c*4+3] = gf_mul(a0,8'h0b) ^ gf_mul(a1,8'h0d) ^ gf_mul(a2,8'h09) ^ gf_mul(a3,8'h0e);
      end
      inv_mix_columns = {o[0],o[1],o[2],o[3],o[4],o[5],o[6],o[7],
                          o[8],o[9],o[10],o[11],o[12],o[13],o[14],o[15]};
    end
  endfunction

  // =================================================================
  // Pipeline
  // =================================================================
  localparam DEPTH = 11;

  reg [127:0]  state_pipe [0:DEPTH-1];
  reg          valid_pipe [0:DEPTH-1];
  reg [1407:0] rks_stage  [0:DEPTH-1];
  reg [1407:0] rks_new;

  integer si;

  always @(posedge clk) begin
    if (rst) begin
      for (si = 0; si < DEPTH; si = si + 1) begin
        state_pipe[si] <= 128'h0;
        valid_pipe[si] <= 1'b0;
        rks_stage[si]  <= 1407'h0;
      end
      valid_out <= 1'b0;
      done      <= 1'b0;
      data_out  <= 128'h0;
    end else begin
      if (start && valid_in) begin
        rks_new = expand_key(key_in);
        state_pipe[0] <= add_round_key(data_in, get_rk(rks_new, 10));
        rks_stage[0]  <= rks_new;
        valid_pipe[0] <= 1'b1;
      end else begin
        valid_pipe[0] <= 1'b0;
      end

      for (si = 1; si <= 9; si = si + 1) begin
        state_pipe[si] <= inv_mix_columns(
                             add_round_key(
                               inv_sub_bytes(
                                 inv_shift_rows(state_pipe[si-1])
                               ),
                               get_rk(rks_stage[si-1], 10-si)
                             )
                           );
        rks_stage[si]  <= rks_stage[si-1];
        valid_pipe[si] <= valid_pipe[si-1];
      end

      state_pipe[10] <= add_round_key(
                           inv_sub_bytes(
                             inv_shift_rows(state_pipe[9])
                           ),
                           get_rk(rks_stage[9], 0)
                         );
      rks_stage[10]  <= rks_stage[9];
      valid_pipe[10] <= valid_pipe[9];

      data_out  <= state_pipe[10];
      valid_out <= valid_pipe[10];
      done      <= valid_pipe[10];
    end
  end

endmodule