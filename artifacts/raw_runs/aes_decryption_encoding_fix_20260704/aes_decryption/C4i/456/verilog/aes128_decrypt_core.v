`timescale 1ns/1ps

module aes128_decrypt_core (
    input  [127:0] ciphertext,
    input  [127:0] key,
    output [127:0] plaintext
);
    reg [31:0] w [0:43];
    reg [127:0] rk [0:10];
    reg [127:0] state;
    integer i, r;

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

    function [7:0] invsbox;
        input [7:0] a;
        begin
            case (a)
                8'h00:invsbox=8'h52; 8'h01:invsbox=8'h09; 8'h02:invsbox=8'h6a; 8'h03:invsbox=8'hd5;
                8'h04:invsbox=8'h30; 8'h05:invsbox=8'h36; 8'h06:invsbox=8'ha5; 8'h07:invsbox=8'h38;
                8'h08:invsbox=8'hbf; 8'h09:invsbox=8'h40; 8'h0a:invsbox=8'ha3; 8'h0b:invsbox=8'h9e;
                8'h0c:invsbox=8'h81; 8'h0d:invsbox=8'hf3; 8'h0e:invsbox=8'hd7; 8'h0f:invsbox=8'hfb;
                8'h10:invsbox=8'h7c; 8'h11:invsbox=8'he3; 8'h12:invsbox=8'h39; 8'h13:invsbox=8'h82;
                8'h14:invsbox=8'h9b; 8'h15:invsbox=8'h2f; 8'h16:invsbox=8'hff; 8'h17:invsbox=8'h87;
                8'h18:invsbox=8'h34; 8'h19:invsbox=8'h8e; 8'h1a:invsbox=8'h43; 8'h1b:invsbox=8'h44;
                8'h1c:invsbox=8'hc4; 8'h1d:invsbox=8'hde; 8'h1e:invsbox=8'he9; 8'h1f:invsbox=8'hcb;
                8'h20:invsbox=8'h54; 8'h21:invsbox=8'h7b; 8'h22:invsbox=8'h94; 8'h23:invsbox=8'h32;
                8'h24:invsbox=8'ha6; 8'h25:invsbox=8'hc2; 8'h26:invsbox=8'h23; 8'h27:invsbox=8'h3d;
                8'h28:invsbox=8'hee; 8'h29:invsbox=8'h4c; 8'h2a:invsbox=8'h95; 8'h2b:invsbox=8'h0b;
                8'h2c:invsbox=8'h42; 8'h2d:invsbox=8'hfa; 8'h2e:invsbox=8'hc3; 8'h2f:invsbox=8'h4e;
                8'h30:invsbox=8'h08; 8'h31:invsbox=8'h2e; 8'h32:invsbox=8'ha1; 8'h33:invsbox=8'h66;
                8'h34:invsbox=8'h28; 8'h35:invsbox=8'hd9; 8'h36:invsbox=8'h24; 8'h37:invsbox=8'hb2;
                8'h38:invsbox=8'h76; 8'h39:invsbox=8'h5b; 8'h3a:invsbox=8'ha2; 8'h3b:invsbox=8'h49;
                8'h3c:invsbox=8'h6d; 8'h3d:invsbox=8'h8b; 8'h3e:invsbox=8'hd1; 8'h3f:invsbox=8'h25;
                8'h40:invsbox=8'h72; 8'h41:invsbox=8'hf8; 8'h42:invsbox=8'hf6; 8'h43:invsbox=8'h64;
                8'h44:invsbox=8'h86; 8'h45:invsbox=8'h68; 8'h46:invsbox=8'h98; 8'h47:invsbox=8'h16;
                8'h48:invsbox=8'hd4; 8'h49:invsbox=8'ha4; 8'h4a:invsbox=8'h5c; 8'h4b:invsbox=8'hcc;
                8'h4c:invsbox=8'h5d; 8'h4d:invsbox=8'h65; 8'h4e:invsbox=8'hb6; 8'h4f:invsbox=8'h92;
                8'h50:invsbox=8'h6c; 8'h51:invsbox=8'h70; 8'h52:invsbox=8'h48; 8'h53:invsbox=8'h50;
                8'h54:invsbox=8'hfd; 8'h55:invsbox=8'hed; 8'h56:invsbox=8'hb9; 8'h57:invsbox=8'hda;
                8'h58:invsbox=8'h5e; 8'h59:invsbox=8'h15; 8'h5a:invsbox=8'h46; 8'h5b:invsbox=8'h57;
                8'h5c:invsbox=8'ha7; 8'h5d:invsbox=8'h8d; 8'h5e:invsbox=8'h9d; 8'h5f:invsbox=8'h84;
                8'h60:invsbox=8'h90; 8'h61:invsbox=8'hd8; 8'h62:invsbox=8'hab; 8'h63:invsbox=8'h00;
                8'h64:invsbox=8'h8c; 8'h65:invsbox=8'hbc; 8'h66:invsbox=8'hd3; 8'h67:invsbox=8'h0a;
                8'h68:invsbox=8'hf7; 8'h69:invsbox=8'he4; 8'h6a:invsbox=8'h58; 8'h6b:invsbox=8'h05;
                8'h6c:invsbox=8'hb8; 8'h6d:invsbox=8'hb3; 8'h6e:invsbox=8'h45; 8'h6f:invsbox=8'h06;
                8'h70:invsbox=8'hd0; 8'h71:invsbox=8'h2c; 8'h72:invsbox=8'h1e; 8'h73:invsbox=8'h8f;
                8'h74:invsbox=8'hca; 8'h75:invsbox=8'h3f; 8'h76:invsbox=8'h0f; 8'h77:invsbox=8'h02;
                8'h78:invsbox=8'hc1; 8'h79:invsbox=8'haf; 8'h7a:invsbox=8'hbd; 8'h7b:invsbox=8'h03;
                8'h7c:invsbox=8'h01; 8'h7d:invsbox=8'h13; 8'h7e:invsbox=8'h8a; 8'h7f:invsbox=8'h6b;
                8'h80:invsbox=8'h3a; 8'h81:invsbox=8'h91; 8'h82:invsbox=8'h11; 8'h83:invsbox=8'h41;
                8'h84:invsbox=8'h4f; 8'h85:invsbox=8'h67; 8'h86:invsbox=8'hdc; 8'h87:invsbox=8'hea;
                8'h88:invsbox=8'h97; 8'h89:invsbox=8'hf2; 8'h8a:invsbox=8'hcf; 8'h8b:invsbox=8'hce;
                8'h8c:invsbox=8'hf0; 8'h8d:invsbox=8'hb4; 8'h8e:invsbox=8'he6; 8'h8f:invsbox=8'h73;
                8'h90:invsbox=8'h96; 8'h91:invsbox=8'hac; 8'h92:invsbox=8'h74; 8'h93:invsbox=8'h22;
                8'h94:invsbox=8'he7; 8'h95:invsbox=8'had; 8'h96:invsbox=8'h35; 8'h97:invsbox=8'h85;
                8'h98:invsbox=8'he2; 8'h99:invsbox=8'hf9; 8'h9a:invsbox=8'h37; 8'h9b:invsbox=8'he8;
                8'h9c:invsbox=8'h1c; 8'h9d:invsbox=8'h75; 8'h9e:invsbox=8'hdf; 8'h9f:invsbox=8'h6e;
                8'ha0:invsbox=8'h47; 8'ha1:invsbox=8'hf1; 8'ha2:invsbox=8'h1a; 8'ha3:invsbox=8'h71;
                8'ha4:invsbox=8'h1d; 8'ha5:invsbox=8'h29; 8'ha6:invsbox=8'hc5; 8'ha7:invsbox=8'h89;
                8'ha8:invsbox=8'h6f; 8'ha9:invsbox=8'hb7; 8'haa:invsbox=8'h62; 8'hab:invsbox=8'h0e;
                8'hac:invsbox=8'haa; 8'had:invsbox=8'h18; 8'hae:invsbox=8'hbe; 8'haf:invsbox=8'h1b;
                8'hb0:invsbox=8'hfc; 8'hb1:invsbox=8'h56; 8'hb2:invsbox=8'h3e; 8'hb3:invsbox=8'h4b;
                8'hb4:invsbox=8'hc6; 8'hb5:invsbox=8'hd2; 8'hb6:invsbox=8'h79; 8'hb7:invsbox=8'h20;
                8'hb8:invsbox=8'h9a; 8'hb9:invsbox=8'hdb; 8'hba:invsbox=8'hc0; 8'hbb:invsbox=8'hfe;
                8'hbc:invsbox=8'h78; 8'hbd:invsbox=8'hcd; 8'hbe:invsbox=8'h5a; 8'hbf:invsbox=8'hf4;
                8'hc0:invsbox=8'h1f; 8'hc1:invsbox=8'hdd; 8'hc2:invsbox=8'ha8; 8'hc3:invsbox=8'h33;
                8'hc4:invsbox=8'h88; 8'hc5:invsbox=8'h07; 8'hc6:invsbox=8'hc7; 8'hc7:invsbox=8'h31;
                8'hc8:invsbox=8'hb1; 8'hc9:invsbox=8'h12; 8'hca:invsbox=8'h10; 8'hcb:invsbox=8'h59;
                8'hcc:invsbox=8'h27; 8'hcd:invsbox=8'h80; 8'hce:invsbox=8'hec; 8'hcf:invsbox=8'h5f;
                8'hd0:invsbox=8'h60; 8'hd1:invsbox=8'h51; 8'hd2:invsbox=8'h7f; 8'hd3:invsbox=8'ha9;
                8'hd4:invsbox=8'h19; 8'hd5:invsbox=8'hb5; 8'hd6:invsbox=8'h4a; 8'hd7:invsbox=8'h0d;
                8'hd8:invsbox=8'h2d; 8'hd9:invsbox=8'he5; 8'hda:invsbox=8'h7a; 8'hdb:invsbox=8'h9f;
                8'hdc:invsbox=8'h93; 8'hdd:invsbox=8'hc9; 8'hde:invsbox=8'h9c; 8'hdf:invsbox=8'hef;
                8'he0:invsbox=8'ha0; 8'he1:invsbox=8'he0; 8'he2:invsbox=8'h3b; 8'he3:invsbox=8'h4d;
                8'he4:invsbox=8'hae; 8'he5:invsbox=8'h2a; 8'he6:invsbox=8'hf5; 8'he7:invsbox=8'hb0;
                8'he8:invsbox=8'hc8; 8'he9:invsbox=8'heb; 8'hea:invsbox=8'hbb; 8'heb:invsbox=8'h3c;
                8'hec:invsbox=8'h83; 8'hed:invsbox=8'h53; 8'hee:invsbox=8'h99; 8'hef:invsbox=8'h61;
                8'hf0:invsbox=8'h17; 8'hf1:invsbox=8'h2b; 8'hf2:invsbox=8'h04; 8'hf3:invsbox=8'h7e;
                8'hf4:invsbox=8'hba; 8'hf5:invsbox=8'h77; 8'hf6:invsbox=8'hd6; 8'hf7:invsbox=8'h26;
                8'hf8:invsbox=8'he1; 8'hf9:invsbox=8'h69; 8'hfa:invsbox=8'h14; 8'hfb:invsbox=8'h63;
                8'hfc:invsbox=8'h55; 8'hfd:invsbox=8'h21; 8'hfe:invsbox=8'h0c; 8'hff:invsbox=8'h7d;
            endcase
        end
    endfunction

    function [31:0] subword; input [31:0] x; begin subword={sbox(x[31:24]),sbox(x[23:16]),sbox(x[15:8]),sbox(x[7:0])}; end endfunction
    function [31:0] rotword; input [31:0] x; begin rotword={x[23:0],x[31:24]}; end endfunction

    function [31:0] rcon;
        input integer n;
        begin
            case (n)
                1:rcon=32'h01000000; 2:rcon=32'h02000000; 3:rcon=32'h04000000; 4:rcon=32'h08000000; 5:rcon=32'h10000000;
                6:rcon=32'h20000000; 7:rcon=32'h40000000; 8:rcon=32'h80000000; 9:rcon=32'h1b000000; 10:rcon=32'h36000000;
                default:rcon=32'h00000000;
            endcase
        end
    endfunction

    function [7:0] xtime; input [7:0] x; begin xtime={x[6:0],1'b0}^{8'h1b & {8{x[7]}}}; end endfunction
    function [7:0] mul2;  input [7:0] x; begin mul2=xtime(x); end endfunction
    function [7:0] mul4;  input [7:0] x; begin mul4=xtime(mul2(x)); end endfunction
    function [7:0] mul8;  input [7:0] x; begin mul8=xtime(mul4(x)); end endfunction
    function [7:0] mul9;  input [7:0] x; begin mul9=mul8(x)^x; end endfunction
    function [7:0] mul11; input [7:0] x; begin mul11=mul8(x)^mul2(x)^x; end endfunction
    function [7:0] mul13; input [7:0] x; begin mul13=mul8(x)^mul4(x)^x; end endfunction
    function [7:0] mul14; input [7:0] x; begin mul14=mul8(x)^mul4(x)^mul2(x); end endfunction

    function [127:0] inv_shift_rows;
        input [127:0] x;
        reg [7:0] b [0:15];
        begin
            for (i = 0; i < 16; i = i + 1)
                b[i] = x[127 - 8*i -: 8];
            inv_shift_rows = {b[0],b[13],b[10],b[7], b[4],b[1],b[14],b[11], b[8],b[5],b[2],b[15], b[12],b[9],b[6],b[3]};
        end
    endfunction

    function [127:0] inv_sub_bytes;
        input [127:0] x;
        integer j;
        begin
            for (j = 0; j < 16; j = j + 1)
                inv_sub_bytes[127 - 8*j -: 8] = invsbox(x[127 - 8*j -: 8]);
        end
    endfunction

    function [31:0] inv_mix_col;
        input [31:0] c;
        reg [7:0] a0, a1, a2, a3;
        begin
            a0=c[31:24]; a1=c[23:16]; a2=c[15:8]; a3=c[7:0];
            inv_mix_col = {
                mul14(a0)^mul11(a1)^mul13(a2)^mul9(a3),
                mul9(a0)^mul14(a1)^mul11(a2)^mul13(a3),
                mul13(a0)^mul9(a1)^mul14(a2)^mul11(a3),
                mul11(a0)^mul13(a1)^mul9(a2)^mul14(a3)
            };
        end
    endfunction

    function [127:0] inv_mix_columns;
        input [127:0] x;
        begin
            inv_mix_columns = {inv_mix_col(x[127:96]), inv_mix_col(x[95:64]), inv_mix_col(x[63:32]), inv_mix_col(x[31:0])};
        end
    endfunction

    always @* begin
        w[0]=key[127:96]; w[1]=key[95:64]; w[2]=key[63:32]; w[3]=key[31:0];

        for (i = 4; i < 44; i = i + 1) begin
            if ((i % 4) == 0)
                w[i] = w[i-4] ^ subword(rotword(w[i-1])) ^ rcon(i/4);
            else
                w[i] = w[i-4] ^ w[i-1];
        end

        for (i = 0; i < 11; i = i + 1)
            rk[i] = {w[4*i], w[4*i+1], w[4*i+2], w[4*i+3]};

        state = ciphertext ^ rk[10];

        for (r = 9; r >= 1; r = r - 1)
            state = inv_mix_columns(inv_sub_bytes(inv_shift_rows(state)) ^ rk[r]);

        state = inv_sub_bytes(inv_shift_rows(state)) ^ rk[0];
    end

    assign plaintext = state;
endmodule