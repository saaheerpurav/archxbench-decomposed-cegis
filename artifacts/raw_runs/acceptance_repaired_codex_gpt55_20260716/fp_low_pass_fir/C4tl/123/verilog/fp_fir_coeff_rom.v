`timescale 1ns/1ps

module fp_fir_coeff_rom (
    input wire [6:0] index,
    output reg [31:0] coeff
);

    always @* begin
        case (index)
            7'd0: coeff = 32'ha012b177;
            7'd1: coeff = 32'hb8899b4e;
            7'd2: coeff = 32'hb9100cde;
            7'd3: coeff = 32'hb9658a36;
            7'd4: coeff = 32'hb9a46f97;
            7'd5: coeff = 32'hb9de9774;
            7'd6: coeff = 32'hba1138b0;
            7'd7: coeff = 32'hba385a59;
            7'd8: coeff = 32'hba64beaf;
            7'd9: coeff = 32'hba8b0c70;
            7'd10: coeff = 32'hbaa5db4a;
            7'd11: coeff = 32'hbac23c16;
            7'd12: coeff = 32'hbadf6632;
            7'd13: coeff = 32'hbafc57d6;
            7'd14: coeff = 32'hbb0bebe1;
            7'd15: coeff = 32'hbb183c76;
            7'd16: coeff = 32'hbb225021;
            7'd17: coeff = 32'hbb29462d;
            7'd18: coeff = 32'hbb2c2f7f;
            7'd19: coeff = 32'hbb2a1427;
            7'd20: coeff = 32'hbb21f9a9;
            7'd21: coeff = 32'hbb12e9c7;
            7'd22: coeff = 32'hbaf7f357;
            7'd23: coeff = 32'hbab8a276;
            7'd24: coeff = 32'hba4cc970;
            7'd25: coeff = 32'h21778b78;
            7'd26: coeff = 32'h3a76ed36;
            7'd27: coeff = 32'h3b064780;
            7'd28: coeff = 32'h3b59ba00;
            7'd29: coeff = 32'h3b9bf8d7;
            7'd30: coeff = 32'h3bd04a05;
            7'd31: coeff = 32'h3c04c2ee;
            7'd32: coeff = 32'h3c23a218;
            7'd33: coeff = 32'h3c447ffc;
            7'd34: coeff = 32'h3c670c62;
            7'd35: coeff = 32'h3c857531;
            7'd36: coeff = 32'h3c97d8e8;
            7'd37: coeff = 32'h3caa7876;
            7'd38: coeff = 32'h3cbd1733;
            7'd39: coeff = 32'h3ccf75c9;
            7'd40: coeff = 32'h3ce1536a;
            7'd41: coeff = 32'h3cf26f15;
            7'd42: coeff = 32'h3d014471;
            7'd43: coeff = 32'h3d08b1ac;
            7'd44: coeff = 32'h3d0f6255;
            7'd45: coeff = 32'h3d153bfc;
            7'd46: coeff = 32'h3d1a2735;
            7'd47: coeff = 32'h3d1e101a;
            7'd48: coeff = 32'h3d20e6b9;
            7'd49: coeff = 32'h3d229f6d;
            7'd50: coeff = 32'h3d23331f;
            7'd51: coeff = 32'h3d229f6d;
            7'd52: coeff = 32'h3d20e6b9;
            7'd53: coeff = 32'h3d1e101a;
            7'd54: coeff = 32'h3d1a2735;
            7'd55: coeff = 32'h3d153bfc;
            7'd56: coeff = 32'h3d0f6255;
            7'd57: coeff = 32'h3d08b1ac;
            7'd58: coeff = 32'h3d014471;
            7'd59: coeff = 32'h3cf26f15;
            7'd60: coeff = 32'h3ce1536a;
            7'd61: coeff = 32'h3ccf75c9;
            7'd62: coeff = 32'h3cbd1733;
            7'd63: coeff = 32'h3caa7876;
            7'd64: coeff = 32'h3c97d8e8;
            7'd65: coeff = 32'h3c857531;
            7'd66: coeff = 32'h3c670c62;
            7'd67: coeff = 32'h3c447ffc;
            7'd68: coeff = 32'h3c23a218;
            7'd69: coeff = 32'h3c04c2ee;
            7'd70: coeff = 32'h3bd04a05;
            7'd71: coeff = 32'h3b9bf8d7;
            7'd72: coeff = 32'h3b59ba00;
            7'd73: coeff = 32'h3b064780;
            7'd74: coeff = 32'h3a76ed36;
            7'd75: coeff = 32'h21778b78;
            7'd76: coeff = 32'hba4cc970;
            7'd77: coeff = 32'hbab8a276;
            7'd78: coeff = 32'hbaf7f357;
            7'd79: coeff = 32'hbb12e9c7;
            7'd80: coeff = 32'hbb21f9a9;
            7'd81: coeff = 32'hbb2a1427;
            7'd82: coeff = 32'hbb2c2f7f;
            7'd83: coeff = 32'hbb29462d;
            7'd84: coeff = 32'hbb225021;
            7'd85: coeff = 32'hbb183c76;
            7'd86: coeff = 32'hbb0bebe1;
            7'd87: coeff = 32'hbafc57d6;
            7'd88: coeff = 32'hbadf6632;
            7'd89: coeff = 32'hbac23c16;
            7'd90: coeff = 32'hbaa5db4a;
            7'd91: coeff = 32'hba8b0c70;
            7'd92: coeff = 32'hba64beaf;
            7'd93: coeff = 32'hba385a59;
            7'd94: coeff = 32'hba1138b0;
            7'd95: coeff = 32'hb9de9774;
            7'd96: coeff = 32'hb9a46f97;
            7'd97: coeff = 32'hb9658a36;
            7'd98: coeff = 32'hb9100cde;
            7'd99: coeff = 32'hb8899b4e;
            7'd100: coeff = 32'ha012b177;
            default: coeff = 32'h00000000;
        endcase
    end

endmodule