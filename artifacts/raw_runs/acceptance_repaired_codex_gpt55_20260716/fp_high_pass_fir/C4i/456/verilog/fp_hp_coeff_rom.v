`timescale 1ns/1ps

module fp_hp_coeff_rom (
    input wire [7:0] idx,
    input wire [7:0] index,
    output reg [31:0] coeff
);
    reg [7:0] addr;

    always @* begin
        if (^index === 1'bx)
            addr = idx;
        else
            addr = index;

        coeff = 32'h00000000;
        case (addr)
            8'd0:   coeff = 32'h21a5e407;
            8'd1:   coeff = 32'h39a1fef1;
            8'd2:   coeff = 32'h3a0a48e5;
            8'd3:   coeff = 32'h3a14dc7c;
            8'd4:   coeff = 32'h39c9729c;
            8'd5:   coeff = 32'h21373cac;
            8'd6:   coeff = 32'hb9fa686f;
            8'd7:   coeff = 32'hba647ae3;
            8'd8:   coeff = 32'hba815b49;
            8'd9:   coeff = 32'hba3564bc;
            8'd10:  coeff = 32'ha2c126e6;
            8'd11:  coeff = 32'h3a696787;
            8'd12:  coeff = 32'h3ad5c178;
            8'd13:  coeff = 32'h3af17343;
            8'd14:  coeff = 32'h3aa82360;
            8'd15:  coeff = 32'h239ded49;
            8'd16:  coeff = 32'hbad3be22;
            8'd17:  coeff = 32'hbb3f7379;
            8'd18:  coeff = 32'hbb556676;
            8'd19:  coeff = 32'hbb12a289;
            8'd20:  coeff = 32'ha4439339;
            8'd21:  coeff = 32'h3b33fb1e;
            8'd22:  coeff = 32'h3ba0cd0c;
            8'd23:  coeff = 32'h3bb13ea7;
            8'd24:  coeff = 32'h3b71153f;
            8'd25:  coeff = 32'ha30bf866;
            8'd26:  coeff = 32'hbb915883;
            8'd27:  coeff = 32'hbc00e7a5;
            8'd28:  coeff = 32'hbc0d333a;
            8'd29:  coeff = 32'hbbbf1429;
            8'd30:  coeff = 32'ha3c43dcb;
            8'd31:  coeff = 32'h3be4ec47;
            8'd32:  coeff = 32'h3c4accff;
            8'd33:  coeff = 32'h3c5e3e69;
            8'd34:  coeff = 32'h3c16b483;
            8'd35:  coeff = 32'h24c72eb7;
            8'd36:  coeff = 32'hbc367814;
            8'd37:  coeff = 32'hbca31ca3;
            8'd38:  coeff = 32'hbcb4ed9c;
            8'd39:  coeff = 32'hbc794bfe;
            8'd40:  coeff = 32'ha403343e;
            8'd41:  coeff = 32'h3c9e21ad;
            8'd42:  coeff = 32'h3d1233f3;
            8'd43:  coeff = 32'h3d2969d5;
            8'd44:  coeff = 32'h3cf73d64;
            8'd45:  coeff = 32'h240c9a35;
            8'd46:  coeff = 32'hbd3cd9b8;
            8'd47:  coeff = 32'hbdcd0395;
            8'd48:  coeff = 32'hbe1a7617;
            8'd49:  coeff = 32'hbe3f721e;
            8'd50:  coeff = 32'h3f4cd56c;
            8'd51:  coeff = 32'hbe3f721e;
            8'd52:  coeff = 32'hbe1a7617;
            8'd53:  coeff = 32'hbdcd0395;
            8'd54:  coeff = 32'hbd3cd9b8;
            8'd55:  coeff = 32'h240c9a35;
            8'd56:  coeff = 32'h3cf73d64;
            8'd57:  coeff = 32'h3d2969d5;
            8'd58:  coeff = 32'h3d1233f3;
            8'd59:  coeff = 32'h3c9e21ad;
            8'd60:  coeff = 32'ha403343e;
            8'd61:  coeff = 32'hbc794bfe;
            8'd62:  coeff = 32'hbcb4ed9c;
            8'd63:  coeff = 32'hbca31ca3;
            8'd64:  coeff = 32'hbc367814;
            8'd65:  coeff = 32'h24c72eb7;
            8'd66:  coeff = 32'h3c16b483;
            8'd67:  coeff = 32'h3c5e3e69;
            8'd68:  coeff = 32'h3c4accff;
            8'd69:  coeff = 32'h3be4ec47;
            8'd70:  coeff = 32'ha3c43dcb;
            8'd71:  coeff = 32'hbbbf1429;
            8'd72:  coeff = 32'hbc0d333a;
            8'd73:  coeff = 32'hbc00e7a5;
            8'd74:  coeff = 32'hbb915883;
            8'd75:  coeff = 32'ha30bf866;
            8'd76:  coeff = 32'h3b71153f;
            8'd77:  coeff = 32'h3bb13ea7;
            8'd78:  coeff = 32'h3ba0cd0c;
            8'd79:  coeff = 32'h3b33fb1e;
            8'd80:  coeff = 32'ha4439339;
            8'd81:  coeff = 32'hbb12a289;
            8'd82:  coeff = 32'hbb556676;
            8'd83:  coeff = 32'hbb3f7379;
            8'd84:  coeff = 32'hbad3be22;
            8'd85:  coeff = 32'h239ded49;
            8'd86:  coeff = 32'h3aa82360;
            8'd87:  coeff = 32'h3af17343;
            8'd88:  coeff = 32'h3ad5c178;
            8'd89:  coeff = 32'h3a696787;
            8'd90:  coeff = 32'ha2c126e6;
            8'd91:  coeff = 32'hba3564bc;
            8'd92:  coeff = 32'hba815b49;
            8'd93:  coeff = 32'hba647ae3;
            8'd94:  coeff = 32'hb9fa686f;
            8'd95:  coeff = 32'h21373cac;
            8'd96:  coeff = 32'h39c9729c;
            8'd97:  coeff = 32'h3a14dc7c;
            8'd98:  coeff = 32'h3a0a48e5;
            8'd99:  coeff = 32'h39a1fef1;
            8'd100: coeff = 32'h21a5e407;
            default: coeff = 32'h00000000;
        endcase
    end
endmodule