`timescale 1ns/1ps

module fp_fir_coeff_rom (
    input  wire [7:0]  tap_idx,
    output reg  [31:0] coeff
);

  always @* begin
    case (tap_idx)
      8'd0:   coeff = 32'h9f92b17f;
      8'd1:   coeff = 32'hb8099b56;
      8'd2:   coeff = 32'hb8900ce6;
      8'd3:   coeff = 32'hb8e58a3e;
      8'd4:   coeff = 32'hb9246f9f;
      8'd5:   coeff = 32'hb95e977c;
      8'd6:   coeff = 32'hb99138b8;
      8'd7:   coeff = 32'hb9b85a61;
      8'd8:   coeff = 32'hb9e4beb7;
      8'd9:   coeff = 32'hba0b0c78;
      8'd10:  coeff = 32'hba25db52;
      8'd11:  coeff = 32'hba423c1e;
      8'd12:  coeff = 32'hba5f663a;
      8'd13:  coeff = 32'hba7c57de;
      8'd14:  coeff = 32'hba8bebe9;
      8'd15:  coeff = 32'hba983c7e;
      8'd16:  coeff = 32'hbaa25029;
      8'd17:  coeff = 32'hbaa94635;
      8'd18:  coeff = 32'hbaac2f87;
      8'd19:  coeff = 32'hbaaa142f;
      8'd20:  coeff = 32'hbaa1f9b1;
      8'd21:  coeff = 32'hba92e9cf;
      8'd22:  coeff = 32'hba77f35f;
      8'd23:  coeff = 32'hba38a27e;
      8'd24:  coeff = 32'hb9ccc978;
      8'd25:  coeff = 32'h20f78b80;
      8'd26:  coeff = 32'h39f6ed3e;
      8'd27:  coeff = 32'h3a864788;
      8'd28:  coeff = 32'h3ad9ba08;
      8'd29:  coeff = 32'h3b1bf8df;
      8'd30:  coeff = 32'h3b504a0d;
      8'd31:  coeff = 32'h3b84c2f6;
      8'd32:  coeff = 32'h3ba3a220;
      8'd33:  coeff = 32'h3bc48004;
      8'd34:  coeff = 32'h3be70c6a;
      8'd35:  coeff = 32'h3c057539;
      8'd36:  coeff = 32'h3c17d8f0;
      8'd37:  coeff = 32'h3c2a787e;
      8'd38:  coeff = 32'h3c3d173b;
      8'd39:  coeff = 32'h3c4f75d1;
      8'd40:  coeff = 32'h3c615372;
      8'd41:  coeff = 32'h3c726f1d;
      8'd42:  coeff = 32'h3c814479;
      8'd43:  coeff = 32'h3c88b1b4;
      8'd44:  coeff = 32'h3c8f625d;
      8'd45:  coeff = 32'h3c953c04;
      8'd46:  coeff = 32'h3c9a273d;
      8'd47:  coeff = 32'h3c9e1022;
      8'd48:  coeff = 32'h3ca0e6c1;
      8'd49:  coeff = 32'h3ca29f75;
      8'd50:  coeff = 32'h3ca33327;
      8'd51:  coeff = 32'h3ca29f75;
      8'd52:  coeff = 32'h3ca0e6c1;
      8'd53:  coeff = 32'h3c9e1022;
      8'd54:  coeff = 32'h3c9a273d;
      8'd55:  coeff = 32'h3c953c04;
      8'd56:  coeff = 32'h3c8f625d;
      8'd57:  coeff = 32'h3c88b1b4;
      8'd58:  coeff = 32'h3c814479;
      8'd59:  coeff = 32'h3c726f1d;
      8'd60:  coeff = 32'h3c615372;
      8'd61:  coeff = 32'h3c4f75d1;
      8'd62:  coeff = 32'h3c3d173b;
      8'd63:  coeff = 32'h3c2a787e;
      8'd64:  coeff = 32'h3c17d8f0;
      8'd65:  coeff = 32'h3c057539;
      8'd66:  coeff = 32'h3be70c6a;
      8'd67:  coeff = 32'h3bc48004;
      8'd68:  coeff = 32'h3ba3a220;
      8'd69:  coeff = 32'h3b84c2f6;
      8'd70:  coeff = 32'h3b504a0d;
      8'd71:  coeff = 32'h3b1bf8df;
      8'd72:  coeff = 32'h3ad9ba08;
      8'd73:  coeff = 32'h3a864788;
      8'd74:  coeff = 32'h39f6ed3e;
      8'd75:  coeff = 32'h20f78b80;
      8'd76:  coeff = 32'hb9ccc978;
      8'd77:  coeff = 32'hba38a27e;
      8'd78:  coeff = 32'hba77f35f;
      8'd79:  coeff = 32'hba92e9cf;
      8'd80:  coeff = 32'hbaa1f9b1;
      8'd81:  coeff = 32'hbaaa142f;
      8'd82:  coeff = 32'hbaac2f87;
      8'd83:  coeff = 32'hbaa94635;
      8'd84:  coeff = 32'hbaa25029;
      8'd85:  coeff = 32'hba983c7e;
      8'd86:  coeff = 32'hba8bebe9;
      8'd87:  coeff = 32'hba7c57de;
      8'd88:  coeff = 32'hba5f663a;
      8'd89:  coeff = 32'hba423c1e;
      8'd90:  coeff = 32'hba25db52;
      8'd91:  coeff = 32'hba0b0c78;
      8'd92:  coeff = 32'hb9e4beb7;
      8'd93:  coeff = 32'hb9b85a61;
      8'd94:  coeff = 32'hb99138b8;
      8'd95:  coeff = 32'hb95e977c;
      8'd96:  coeff = 32'hb9246f9f;
      8'd97:  coeff = 32'hb8e58a3e;
      8'd98:  coeff = 32'hb8900ce6;
      8'd99:  coeff = 32'hb8099b56;
      8'd100: coeff = 32'h9f92b17f;
      default: coeff = 32'h00000000;
    endcase
  end

endmodule