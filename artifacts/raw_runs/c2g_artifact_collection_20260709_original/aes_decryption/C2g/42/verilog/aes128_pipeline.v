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

  function [7:0] sbox;
    input [7:0] a;
    begin
      case (a)
        8'h00:sbox=8'h63; 8'h01:sbox=8'h7c; 8'h02:sbox=8'h77; 8'h03:sbox=8'h7b;
        8'h04:sbox=8'hf2; 8'h05:sbox=8'h6b; 8'h06:sbox=8'h6f; 8'h07:sbox=8'hc5;
        8'h08:sbox=8'h30; 8'h09:sbox=8'h01; 8'h0a:sbox=8'h67; 8'h0b:sbox=8'h2b;
        8'h0c:sbox=8'hfe; 8'h0d:sbox=8'hd7; 8'h0e:sbox=8'hab; 8'h0f:sbox=8'h76;
        8'h10:sbox=8'hca; 8'h11:sbox=8'h82; 8'h12:sbox=8'hc9; 8'h13:sbox=8'h7d;
        8'h14:sbox=8'hfa; 8'h15:sbox=8'h59; 8'h16:sbox=8'h47; 8'h17:sbox=8'hf0;
        8'h18:sbox=8'had; 8'h19:sbox=8'hd4; 8'h1a:sbox=8'ha2; 8'h1b:sbox=8'haf;
        8'h1c:sbox=8'h9c; 8'h1d:sbox=8'ha4; 8'h1e:sbox=8'h72; 8'h1f:sbox=8'hc0;
        8'h20:sbox=8'hb7; 8'h21:sbox=8'hfd; 8'h22:sbox=8'h93; 8'h23:sbox=8'h26;
        8'h24:sbox=8'h36; 8'h25:sbox=8'h3f; 8'h26:sbox=8'hf7; 8'h27:sbox=8'hcc;
        8'h28:sbox=8'h34; 8'h29:sbox=8'ha5; 8'h2a:sbox=8'he5; 8'h2b:sbox=8'hf1;
        8'h2c:sbox=8'h71; 8'h2d:sbox=8'hd8; 8'h2e:sbox=8'h31; 8'h2f:sbox=8'h15;
        8'h30:sbox=8'h04; 8'h31:sbox=8'hc7; 8'h32:sbox=8'h23; 8'h33:sbox=8'hc3;
        8'h34:sbox=8'h18; 8'h35:sbox=8'h96; 8'h36:sbox=8'h05; 8'h37:sbox=8'h9a;
        8'h38:sbox=8'h07; 8'h39:sbox=8'h12; 8'h3a:sbox=8'h80; 8'h3b:sbox=8'he2;
        8'h3c:sbox=8'heb; 8'h3d:sbox=8'h27; 8'h3e:sbox=8'hb2; 8'h3f:sbox=8'h75;
        8'h40:sbox=8'h09; 8'h41:sbox=8'h83; 8'h42:sbox=8'h2c; 8'h43:sbox=8'h1a;
        8'h44:sbox=8'h1b; 8'h45:sbox=8'h6e; 8'h46:sbox=8'h5a; 8'h47:sbox=8'ha0;
        8'h48:sbox=8'h52; 8'h49:sbox=8'h3b; 8'h4a:sbox=8'hd6; 8'h4b:sbox=8'hb3;
        8'h4c:sbox=8'h29; 8'h4d:sbox=8'he3; 8'h4e:sbox=8'h2f; 8'h4f:sbox=8'h84;
        8'h50:sbox=8'h53; 8'h51:sbox=8'hd1; 8'h52:sbox=8'h00; 8'h53:sbox=8'hed;
        8'h54:sbox=8'h20; 8'h55:sbox=8'hfc; 8'h56:sbox=8'hb1; 8'h57:sbox=8'h5b;
        8'h58:sbox=8'h6a; 8'h59:sbox=8'hcb; 8'h5a:sbox=8'hbe; 8'h5b:sbox=8'h39;
        8'h5c:sbox=8'h4a; 8'h5d:sbox=8'h4c; 8'h5e:sbox=8'h58; 8'h5f:sbox=8'hcf;
        8'h60:sbox=8'hd0; 8'h61:sbox=8'hef; 8'h62:sbox=8'haa; 8'h63:sbox=8'hfb;
        8'h64:sbox=8'h43; 8'h65:sbox=8'h4d; 8'h66:sbox=8'h33; 8'h67:sbox=8'h85;
        8'h68:sbox=8'h45; 8'h69:sbox=8'hf9; 8'h6a:sbox=8'h02; 8'h6b:sbox=8'h7f;
        8'h6c:sbox=8'h50; 8'h6d:sbox=8'h3c; 8'h6e:sbox=8'h9f; 8'h6f:sbox=8'ha8;
        8'h70:sbox=8'h51; 8'h71:sbox=8'ha3; 8'h72:sbox=8'h40; 8'h73:sbox=8'h8f;
        8'h74:sbox=8'h92; 8'h75:sbox=8'h9d; 8'h76:sbox=8'h38; 8'h77:sbox=8'hf5;
        8'h78:sbox=8'hbc; 8'h79:sbox=8'hb6; 8'h7a:sbox=8'hda; 8'h7b:sbox=8'h21;
        8'h7c:sbox=8'h10; 8'h7d:sbox=8'hff; 8'h7e:sbox=8'hf3; 8'h7f:sbox=8'hd2;
        8'h80:sbox=8'hcd; 8'h81:sbox=8'h0c; 8'h82:sbox=8'h13; 8'h83:sbox=8'hec;
        8'h84:sbox=8'h5f; 8'h85:sbox=8'h97; 8'h86:sbox=8'h44; 8'h87:sbox=8'h17;
        8'h88:sbox=8'hc4; 8'h89:sbox=8'ha7; 8'h8a:sbox=8'h7e; 8'h8b:sbox=8'h3d;
        8'h8c:sbox=8'h64; 8'h8d:sbox=8'h5d; 8'h8e:sbox=8'h19; 8'h8f:sbox=8'h73;
        8'h90:sbox=8'h60; 8'h91:sbox=8'h81; 8'h92:sbox=8'h4f; 8'h93:sbox=8'hdc;
        8'h94:sbox=8'h22; 8'h95:sbox=8'h2a; 8'h96:sbox=8'h90; 8'h97:sbox=8'h88;
        8'h98:sbox=8'h46; 8'h99:sbox=8'hee; 8'h9a:sbox=8'hb8; 8'h9b:sbox=8'h14;
        8'h9c:sbox=8'hde; 8'h9d:sbox=8'h5e; 8'h9e:sbox=8'h0b; 8'h9f:sbox=8'hdb;
        8'ha0:sbox=8'he0; 8'ha1:sbox=8'h32; 8'ha2:sbox=8'h3a; 8'ha3:sbox=8'h0a;
        8'ha4:sbox=8'h49; 8'ha5:sbox=8'h06; 8'ha6:sbox=8'h24; 8'ha7:sbox=8'h5c;
        8'ha8:sbox=8'hc2; 8'ha9:sbox=8'hd3; 8'haa:sbox=8'hac; 8'hab:sbox=8'h62;
        8'hac:sbox=8'h91; 8'had:sbox=8'h95; 8'hae:sbox=8'he4; 8'haf:sbox=8'h79;
        8'hb0:sbox=8'he7; 8'hb1:sbox=8'hc8; 8'hb2:sbox=8'h37; 8'hb3:sbox=8'h6d;
        8'hb4:sbox=8'h8d; 8'hb5:sbox=8'hd5; 8'hb6:sbox=8'h4e; 8'hb7:sbox=8'ha9;
        8'hb8:sbox=8'h6c; 8'hb9:sbox=8'h56; 8'hba:sbox=8'hf4; 8'hbb:sbox=8'hea;
        8'hbc:sbox=8'h65; 8'hbd:sbox=8'h7a; 8'hbe:sbox=8'hae; 8'hbf:sbox=8'h08;
        8'hc0:sbox=8'hba; 8'hc1:sbox=8'h78; 8'hc2:sbox=8'h25; 8'hc3:sbox=8'h2e;
        8'hc4:sbox=8'h1c; 8'hc5:sbox=8'ha6; 8'hc6:sbox=8'hb4; 8'hc7:sbox=8'hc6;
        8'hc8:sbox=8'he8; 8'hc9:sbox=8'hdd; 8'hca:sbox=8'h74; 8'hcb:sbox=8'h1f;
        8'hcc:sbox=8'h4b; 8'hcd:sbox=8'hbd; 8'hce:sbox=8'h8b; 8'hcf:sbox=8'h8a;
        8'hd0:sbox=8'h70; 8'hd1:sbox=8'h3e; 8'hd2:sbox=8'hb5; 8'hd3:sbox=8'h66;
        8'hd4:sbox=8'h48; 8'hd5:sbox=8'h03; 8'hd6:sbox=8'hf6; 8'hd7:sbox=8'h0e;
        8'hd8:sbox=8'h61; 8'hd9:sbox=8'h35; 8'hda:sbox=8'h57; 8'hdb:sbox=8'hb9;
        8'hdc:sbox=8'h86; 8'hdd:sbox=8'hc1; 8'hde:sbox=8'h1d; 8'hdf:sbox=8'h9e;
        8'he0:sbox=8'he1; 8'he1:sbox=8'hf8; 8'he2:sbox=8'h98; 8'he3:sbox=8'h11;
        8'he4:sbox=8'h69; 8'he5:sbox=8'hd9; 8'he6:sbox=8'h8e; 8'he7:sbox=8'h94;
        8'he8:sbox=8'h9b; 8'he9:sbox=8'h1e; 8'hea:sbox=8'h87; 8'heb:sbox=8'he9;
        8'hec:sbox=8'hce; 8'hed:sbox=8'h55; 8'hee:sbox=8'h28; 8'hef:sbox=8'hdf;
        8'hf0:sbox=8'h8c; 8'hf1:sbox=8'ha1; 8'hf2:sbox=8'h89; 8'hf3:sbox=8'h0d;
        8'hf4:sbox=8'hbf; 8'hf5:sbox=8'he6; 8'hf6:sbox=8'h42; 8'hf7:sbox=8'h68;
        8'hf8:sbox=8'h41; 8'hf9:sbox=8'h99; 8'hfa:sbox=8'h2d; 8'hfb:sbox=8'h0f;
        8'hfc:sbox=8'hb0; 8'hfd:sbox=8'h54; 8'hfe:sbox=8'hbb; 8'hff:sbox=8'h16;
      endcase
    end
  endfunction

  function [7:0] inv_sbox;
    input [7:0] a;
    begin
      case (a)
        8'h00:inv_sbox=8'h52; 8'h01:inv_sbox=8'h09; 8'h02:inv_sbox=8'h6a; 8'h03:inv_sbox=8'hd5;
        8'h04:inv_sbox=8'h30; 8'h05:inv_sbox=8'h36; 8'h06:inv_sbox=8'ha5; 8'h07:inv_sbox=8'h38;
        8'h08:inv_sbox=8'hbf; 8'h09:inv_sbox=8'h40; 8'h0a:inv_sbox=8'ha3; 8'h0b:inv_sbox=8'h9e;
        8'h0c:inv_sbox=8'h81; 8'h0d:inv_sbox=8'hf3; 8'h0e:inv_sbox=8'hd7; 8'h0f:inv_sbox=8'hfb;
        8'h10:inv_sbox=8'h7c; 8'h11:inv_sbox=8'he3; 8'h12:inv_sbox=8'h39; 8'h13:inv_sbox=8'h82;
        8'h14:inv_sbox=8'h9b; 8'h15:inv_sbox=8'h2f; 8'h16:inv_sbox=8'hff; 8'h17:inv_sbox=8'h87;
        8'h18:inv_sbox=8'h34; 8'h19:inv_sbox=8'h8e; 8'h1a:inv_sbox=8'h43; 8'h1b:inv_sbox=8'h44;
        8'h1c:inv_sbox=8'hc4; 8'h1d:inv_sbox=8'hde; 8'h1e:inv_sbox=8'he9; 8'h1f:inv_sbox=8'hcb;
        8'h20:inv_sbox=8'h54; 8'h21:inv_sbox=8'h7b; 8'h22:inv_sbox=8'h94; 8'h23:inv_sbox=8'h32;
        8'h24:inv_sbox=8'ha6; 8'h25:inv_sbox=8'hc2; 8'h26:inv_sbox=8'h23; 8'h27:inv_sbox=8'h3d;
        8'h28:inv_sbox=8'hee; 8'h29:inv_sbox=8'h4c; 8'h2a:inv_sbox=8'h95; 8'h2b:inv_sbox=8'h0b;
        8'h2c:inv_sbox=8'h42; 8'h2d:inv_sbox=8'hfa; 8'h2e:inv_sbox=8'hc3; 8'h2f:inv_sbox=8'h4e;
        8'h30:inv_sbox=8'h08; 8'h31:inv_sbox=8'h2e; 8'h32:inv_sbox=8'ha1; 8'h33:inv_sbox=8'h66;
        8'h34:inv_sbox=8'h28; 8'h35:inv_sbox=8'hd9; 8'h36:inv_sbox=8'h24; 8'h37:inv_sbox=8'hb2;
        8'h38:inv_sbox=8'h76; 8'h39:inv_sbox=8'h5b; 8'h3a:inv_sbox=8'ha2; 8'h3b:inv_sbox=8'h49;
        8'h3c:inv_sbox=8'h6d; 8'h3d:inv_sbox=8'h8b; 8'h3e:inv_sbox=8'hd1; 8'h3f:inv_sbox=8'h25;
        8'h40:inv_sbox=8'h72; 8'h41:inv_sbox=8'hf8; 8'h42:inv_sbox=8'hf6; 8'h43:inv_sbox=8'h64;
        8'h44:inv_sbox=8'h86; 8'h45:inv_sbox=8'h68; 8'h46:inv_sbox=8'h98; 8'h47:inv_sbox=8'h16;
        8'h48:inv_sbox=8'hd4; 8'h49:inv_sbox=8'ha4; 8'h4a:inv_sbox=8'h5c; 8'h4b:inv_sbox=8'hcc;
        8'h4c:inv_sbox=8'h5d; 8'h4d:inv_sbox=8'h65; 8'h4e:inv_sbox=8'hb6; 8'h4f:inv_sbox=8'h92;
        8'h50:inv_sbox=8'h6c; 8'h51:inv_sbox=8'h70; 8'h52:inv_sbox=8'h48; 8'h53:inv_sbox=8'h50;
        8'h54:inv_sbox=8'hfd; 8'h55:inv_sbox=8'hed; 8'h56:inv_sbox=8'hb9; 8'h57:inv_sbox=8'hda;
        8'h58:inv_sbox=8'h5e; 8'h59:inv_sbox=8'h15; 8'h5a:inv_sbox=8'h46; 8'h5b:inv_sbox=8'h57;
        8'h5c:inv_sbox=8'ha7; 8'h5d:inv_sbox=8'h8d; 8'h5e:inv_sbox=8'h9d; 8'h5f:inv_sbox=8'h84;
        8'h60:inv_sbox=8'h90; 8'h61:inv_sbox=8'hd8; 8'h62:inv_sbox=8'hab; 8'h63:inv_sbox=8'h00;
        8'h64:inv_sbox=8'h8c; 8'h65:inv_sbox=8'hbc; 8'h66:inv_sbox=8'hd3; 8'h67:inv_sbox=8'h0a;
        8'h68:inv_sbox=8'hf7; 8'h69:inv_sbox=8'he4; 8'h6a:inv_sbox=8'h58; 8'h6b:inv_sbox=8'h05;
        8'h6c:inv_sbox=8'hb8; 8'h6d:inv_sbox=8'hb3; 8'h6e:inv_sbox=8'h45; 8'h6f:inv_sbox=8'h06;
        8'h70:inv_sbox=8'hd0; 8'h71:inv_sbox=8'h2c; 8'h72:inv_sbox=8'h1e; 8'h73:inv_sbox=8'h8f;
        8'h74:inv_sbox=8'hca; 8'h75:inv_sbox=8'h3f; 8'h76:inv_sbox=8'h0f; 8'h77:inv_sbox=8'h02;
        8'h78:inv_sbox=8'hc1; 8'h79:inv_sbox=8'haf; 8'h7a:inv_sbox=8'hbd; 8'h7b:inv_sbox=8'h03;
        8'h7c:inv_sbox=8'h01; 8'h7d:inv_sbox=8'h13; 8'h7e:inv_sbox=8'h8a; 8'h7f:inv_sbox=8'h6b;
        8'h80:inv_sbox=8'h3a; 8'h81:inv_sbox=8'h91; 8'h82:inv_sbox=8'h11; 8'h83:inv_sbox=8'h41;
        8'h84:inv_sbox=8'h4f; 8'h85:inv_sbox=8'h67; 8'h86:inv_sbox=8'hdc; 8'h87:inv_sbox=8'hea;
        8'h88:inv_sbox=8'h97; 8'h89:inv_sbox=8'hf2; 8'h8a:inv_sbox=8'hcf; 8'h8b:inv_sbox=8'hce;
        8'h8c:inv_sbox=8'hf0; 8'h8d:inv_sbox=8'hb4; 8'h8e:inv_sbox=8'he6; 8'h8f:inv_sbox=8'h73;
        8'h90:inv_sbox=8'h96; 8'h91:inv_sbox=8'hac; 8'h92:inv_sbox=8'h74; 8'h93:inv_sbox=8'h22;
        8'h94:inv_sbox=8'he7; 8'h95:inv_sbox=8'had; 8'h96:inv_sbox=8'h35; 8'h97:inv_sbox=8'h85;
        8'h98:inv_sbox=8'he2; 8'h99:inv_sbox=8'hf9; 8'h9a:inv_sbox=8'h37; 8'h9b:inv_sbox=8'he8;
        8'h9c:inv_sbox=8'h1c; 8'h9d:inv_sbox=8'h75; 8'h9e:inv_sbox=8'hdf; 8'h9f:inv_sbox=8'h6e;
        8'ha0:inv_sbox=8'h47; 8'ha1:inv_sbox=8'hf1; 8'ha2:inv_sbox=8'h1a; 8'ha3:inv_sbox=8'h71;
        8'ha4:inv_sbox=8'h1d; 8'ha5:inv_sbox=8'h29; 8'ha6:inv_sbox=8'hc5; 8'ha7:inv_sbox=8'h89;
        8'ha8:inv_sbox=8'h6f; 8'ha9:inv_sbox=8'hb7; 8'haa:inv_sbox=8'h62; 8'hab:inv_sbox=8'h0e;
        8'hac:inv_sbox=8'haa; 8'had:inv_sbox=8'h18; 8'hae:inv_sbox=8'hbe; 8'haf:inv_sbox=8'h1b;
        8'hb0:inv_sbox=8'hfc; 8'hb1:inv_sbox=8'h56; 8'hb2:inv_sbox=8'h3e; 8'hb3:inv_sbox=8'h4b;
        8'hb4:inv_sbox=8'hc6; 8'hb5:inv_sbox=8'hd2; 8'hb6:inv_sbox=8'h79; 8'hb7:inv_sbox=8'h20;
        8'hb8:inv_sbox=8'h9a; 8'hb9:inv_sbox=8'hdb; 8'hba:inv_sbox=8'hc0; 8'hbb:inv_sbox=8'hfe;
        8'hbc:inv_sbox=8'h78; 8'hbd:inv_sbox=8'hcd; 8'hbe:inv_sbox=8'h5a; 8'hbf:inv_sbox=8'hf4;
        8'hc0:inv_sbox=8'h1f; 8'hc1:inv_sbox=8'hdd; 8'hc2:inv_sbox=8'ha8; 8'hc3:inv_sbox=8'h33;
        8'hc4:inv_sbox=8'h88; 8'hc5:inv_sbox=8'h07; 8'hc6:inv_sbox=8'hc7; 8'hc7:inv_sbox=8'h31;
        8'hc8:inv_sbox=8'hb1; 8'hc9:inv_sbox=8'h12; 8'hca:inv_sbox=8'h10; 8'hcb:inv_sbox=8'h59;
        8'hcc:inv_sbox=8'h27; 8'hcd:inv_sbox=8'h80; 8'hce:inv_sbox=8'hec; 8'hcf:inv_sbox=8'h5f;
        8'hd0:inv_sbox=8'h60; 8'hd1:inv_sbox=8'h51; 8'hd2:inv_sbox=8'h7f; 8'hd3:inv_sbox=8'ha9;
        8'hd4:inv_sbox=8'h19; 8'hd5:inv_sbox=8'hb5; 8'hd6:inv_sbox=8'h4a; 8'hd7:inv_sbox=8'h0d;
        8'hd8:inv_sbox=8'h2d; 8'hd9:inv_sbox=8'he5; 8'hda:inv_sbox=8'h7a; 8'hdb:inv_sbox=8'h9f;
        8'hdc:inv_sbox=8'h93; 8'hdd:inv_sbox=8'hc9; 8'hde:inv_sbox=8'h9c; 8'hdf:inv_sbox=8'hef;
        8'he0:inv_sbox=8'ha0; 8'he1:inv_sbox=8'he0; 8'he2:inv_sbox=8'h3b; 8'he3:inv_sbox=8'h4d;
        8'he4:inv_sbox=8'hae; 8'he5:inv_sbox=8'h2a; 8'he6:inv_sbox=8'hf5; 8'he7:inv_sbox=8'hb0;
        8'he8:inv_sbox=8'hc8; 8'he9:inv_sbox=8'heb; 8'hea:inv_sbox=8'hbb; 8'heb:inv_sbox=8'h3c;
        8'hec:inv_sbox=8'h83; 8'hed:inv_sbox=8'h53; 8'hee:inv_sbox=8'h99; 8'hef:inv_sbox=8'h61;
        8'hf0:inv_sbox=8'h17; 8'hf1:inv_sbox=8'h2b; 8'hf2:inv_sbox=8'h04; 8'hf3:inv_sbox=8'h7e;
        8'hf4:inv_sbox=8'hba; 8'hf5:inv_sbox=8'h77; 8'hf6:inv_sbox=8'hd6; 8'hf7:inv_sbox=8'h26;
        8'hf8:inv_sbox=8'he1; 8'hf9:inv_sbox=8'h69; 8'hfa:inv_sbox=8'h14; 8'hfb:inv_sbox=8'h63;
        8'hfc:inv_sbox=8'h55; 8'hfd:inv_sbox=8'h21; 8'hfe:inv_sbox=8'h0c; 8'hff:inv_sbox=8'h7d;
      endcase
    end
  endfunction

  function [31:0] subword;
    input [31:0] w;
    begin
      subword = {sbox(w[31:24]), sbox(w[23:16]), sbox(w[15:8]), sbox(w[7:0])};
    end
  endfunction

  function [31:0] rotword;
    input [31:0] w;
    begin
      rotword = {w[23:0], w[31:24]};
    end
  endfunction

  function [31:0] rcon;
    input integer i;
    begin
      case (i)
        1:rcon=32'h01000000; 2:rcon=32'h02000000; 3:rcon=32'h04000000;
        4:rcon=32'h08000000; 5:rcon=32'h10000000; 6:rcon=32'h20000000;
        7:rcon=32'h40000000; 8:rcon=32'h80000000; 9:rcon=32'h1b000000;
        10:rcon=32'h36000000; default:rcon=32'h00000000;
      endcase
    end
  endfunction

  function [127:0] round_key;
    input [127:0] key;
    input integer round;
    reg [31:0] w [0:43];
    reg [31:0] temp;
    integer i;
    begin
      w[0]=key[127:96]; w[1]=key[95:64]; w[2]=key[63:32]; w[3]=key[31:0];
      for (i=4; i<44; i=i+1) begin
        temp = w[i-1];
        if ((i % 4) == 0)
          temp = subword(rotword(temp)) ^ rcon(i/4);
        w[i] = w[i-4] ^ temp;
      end
      round_key = {w[4*round], w[4*round+1], w[4*round+2], w[4*round+3]};
    end
  endfunction

  function [7:0] xtime;
    input [7:0] b;
    begin
      xtime = {b[6:0],1'b0} ^ (8'h1b & {8{b[7]}});
    end
  endfunction

  function [7:0] gm2; input [7:0] b; begin gm2 = xtime(b); end endfunction
  function [7:0] gm4; input [7:0] b; begin gm4 = xtime(gm2(b)); end endfunction
  function [7:0] gm8; input [7:0] b; begin gm8 = xtime(gm4(b)); end endfunction
  function [7:0] gm9; input [7:0] b; begin gm9 = gm8(b) ^ b; end endfunction
  function [7:0] gm11; input [7:0] b; begin gm11 = gm8(b) ^ gm2(b) ^ b; end endfunction
  function [7:0] gm13; input [7:0] b; begin gm13 = gm8(b) ^ gm4(b) ^ b; end endfunction
  function [7:0] gm14; input [7:0] b; begin gm14 = gm8(b) ^ gm4(b) ^ gm2(b); end endfunction

  function [7:0] sb;
    input [127:0] s;
    input integer idx;
    begin
      sb = s[127 - idx*8 -: 8];
    end
  endfunction

  function [127:0] inv_shift_rows;
    input [127:0] s;
    begin
      inv_shift_rows = {
        sb(s,0),  sb(s,13), sb(s,10), sb(s,7),
        sb(s,4),  sb(s,1),  sb(s,14), sb(s,11),
        sb(s,8),  sb(s,5),  sb(s,2),  sb(s,15),
        sb(s,12), sb(s,9),  sb(s,6),  sb(s,3)
      };
    end
  endfunction

  function [127:0] inv_sub_bytes;
    input [127:0] s;
    integer i;
    begin
      for (i=0; i<16; i=i+1)
        inv_sub_bytes[127 - i*8 -: 8] = inv_sbox(s[127 - i*8 -: 8]);
    end
  endfunction

  function [31:0] inv_mix_word;
    input [31:0] c;
    reg [7:0] a0, a1, a2, a3;
    begin
      a0=c[31:24]; a1=c[23:16]; a2=c[15:8]; a3=c[7:0];
      inv_mix_word = {
        gm14(a0)^gm11(a1)^gm13(a2)^gm9(a3),
        gm9(a0)^gm14(a1)^gm11(a2)^gm13(a3),
        gm13(a0)^gm9(a1)^gm14(a2)^gm11(a3),
        gm11(a0)^gm13(a1)^gm9(a2)^gm14(a3)
      };
    end
  endfunction

  function [127:0] inv_mix_columns;
    input [127:0] s;
    begin
      inv_mix_columns = {
        inv_mix_word(s[127:96]),
        inv_mix_word(s[95:64]),
        inv_mix_word(s[63:32]),
        inv_mix_word(s[31:0])
      };
    end
  endfunction

  function [127:0] aes_decrypt;
    input [127:0] ct;
    input [127:0] key;
    reg [127:0] st;
    integer r;
    begin
      st = ct ^ round_key(key, 10);
      for (r=9; r>=1; r=r-1) begin
        st = inv_shift_rows(st);
        st = inv_sub_bytes(st);
        st = st ^ round_key(key, r);
        st = inv_mix_columns(st);
      end
      st = inv_shift_rows(st);
      st = inv_sub_bytes(st);
      st = st ^ round_key(key, 0);
      aes_decrypt = st;
    end
  endfunction

  always @(posedge clk) begin
    if (rst) begin
      data_out  <= 128'h0;
      valid_out <= 1'b0;
      done      <= 1'b0;
    end else begin
      valid_out <= 1'b0;
      done      <= 1'b0;
      if (start && valid_in && mode) begin
        data_out  <= aes_decrypt(data_in, key_in);
        valid_out <= 1'b1;
        done      <= 1'b1;
      end
    end
  end

endmodule