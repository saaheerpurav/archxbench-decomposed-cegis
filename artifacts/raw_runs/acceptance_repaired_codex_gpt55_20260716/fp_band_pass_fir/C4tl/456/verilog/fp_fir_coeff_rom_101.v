`timescale 1ns/1ps

module fp_fir_coeff_rom_101 (
    input wire [7:0] index,
    output reg [31:0] coeff
);

  always @* begin
    case (index)
      8'd0:   coeff = 32'h39fd56aa;
      8'd1:   coeff = 32'h39a77386;
      8'd2:   coeff = 32'h39334aac;
      8'd3:   coeff = 32'h386d8991;
      8'd4:   coeff = 32'hb5a5aba3;
      8'd5:   coeff = 32'h37bd8450;
      8'd6:   coeff = 32'h391fc780;
      8'd7:   coeff = 32'h39d475a3;
      8'd8:   coeff = 32'h3a4d6269;
      8'd9:   coeff = 32'h3aa61be3;
      8'd10:  coeff = 32'h3aed3bf0;
      8'd11:  coeff = 32'h3b192db6;
      8'd12:  coeff = 32'h3b347633;
      8'd13:  coeff = 32'h3b418ca6;
      8'd14:  coeff = 32'h3b3a03d9;
      8'd15:  coeff = 32'h3b193e82;
      8'd16:  coeff = 32'h3abb6ece;
      8'd17:  coeff = 32'h391fa206;
      8'd18:  coeff = 32'hbab5ebf4;
      8'd19:  coeff = 32'hbb45facc;
      8'd20:  coeff = 32'hbb9488a1;
      8'd21:  coeff = 32'hbbbaa786;
      8'd22:  coeff = 32'hbbceb76a;
      8'd23:  coeff = 32'hbbcc46b2;
      8'd24:  coeff = 32'hbbb25119;
      8'd25:  coeff = 32'hbb841b84;
      8'd26:  coeff = 32'hbb12f16e;
      8'd27:  coeff = 32'hb9e522de;
      8'd28:  coeff = 32'h3a74a930;
      8'd29:  coeff = 32'h3ab63a39;
      8'd30:  coeff = 32'h3a034101;
      8'd31:  coeff = 32'hbb0600e4;
      8'd32:  coeff = 32'hbbd0625a;
      8'd33:  coeff = 32'hbc49a519;
      8'd34:  coeff = 32'hbc9f93b5;
      8'd35:  coeff = 32'hbcdeddd2;
      8'd36:  coeff = 32'hbd0dbce0;
      8'd37:  coeff = 32'hbd2696ef;
      8'd38:  coeff = 32'hbd35d6f1;
      8'd39:  coeff = 32'hbd37d430;
      8'd40:  coeff = 32'hbd29e7d2;
      8'd41:  coeff = 32'hbd0adcc4;
      8'd42:  coeff = 32'hbcb67535;
      8'd43:  coeff = 32'hbbeaf5be;
      8'd44:  coeff = 32'h3c2a8ac6;
      8'd45:  coeff = 32'h3ceeaa3c;
      8'd46:  coeff = 32'h3d42697f;
      8'd47:  coeff = 32'h3d82ae39;
      8'd48:  coeff = 32'h3d9d14a6;
      8'd49:  coeff = 32'h3dadfa04;
      8'd50:  coeff = 32'h3db3ca74;
      8'd51:  coeff = 32'h3dadfa04;
      8'd52:  coeff = 32'h3d9d14a6;
      8'd53:  coeff = 32'h3d82ae39;
      8'd54:  coeff = 32'h3d42697f;
      8'd55:  coeff = 32'h3ceeaa3c;
      8'd56:  coeff = 32'h3c2a8ac6;
      8'd57:  coeff = 32'hbbeaf5be;
      8'd58:  coeff = 32'hbcb67535;
      8'd59:  coeff = 32'hbd0adcc4;
      8'd60:  coeff = 32'hbd29e7d2;
      8'd61:  coeff = 32'hbd37d430;
      8'd62:  coeff = 32'hbd35d6f1;
      8'd63:  coeff = 32'hbd2696ef;
      8'd64:  coeff = 32'hbd0dbce0;
      8'd65:  coeff = 32'hbcdeddd2;
      8'd66:  coeff = 32'hbc9f93b5;
      8'd67:  coeff = 32'hbc49a519;
      8'd68:  coeff = 32'hbbd0625a;
      8'd69:  coeff = 32'hbb0600e4;
      8'd70:  coeff = 32'h3a034101;
      8'd71:  coeff = 32'h3ab63a39;
      8'd72:  coeff = 32'h3a74a930;
      8'd73:  coeff = 32'hb9e522de;
      8'd74:  coeff = 32'hbb12f16e;
      8'd75:  coeff = 32'hbb841b84;
      8'd76:  coeff = 32'hbbb25119;
      8'd77:  coeff = 32'hbbcc46b2;
      8'd78:  coeff = 32'hbbceb76a;
      8'd79:  coeff = 32'hbbbaa786;
      8'd80:  coeff = 32'hbb9488a1;
      8'd81:  coeff = 32'hbb45facc;
      8'd82:  coeff = 32'hbab5ebf4;
      8'd83:  coeff = 32'h391fa206;
      8'd84:  coeff = 32'h3abb6ece;
      8'd85:  coeff = 32'h3b193e82;
      8'd86:  coeff = 32'h3b3a03d9;
      8'd87:  coeff = 32'h3b418ca6;
      8'd88:  coeff = 32'h3b347633;
      8'd89:  coeff = 32'h3b192db6;
      8'd90:  coeff = 32'h3aed3bf0;
      8'd91:  coeff = 32'h3aa61be3;
      8'd92:  coeff = 32'h3a4d6269;
      8'd93:  coeff = 32'h39d475a3;
      8'd94:  coeff = 32'h391fc780;
      8'd95:  coeff = 32'h37bd8450;
      8'd96:  coeff = 32'hb5a5aba3;
      8'd97:  coeff = 32'h386d8991;
      8'd98:  coeff = 32'h39334aac;
      8'd99:  coeff = 32'h39a77386;
      8'd100: coeff = 32'h39fd56aa;
      default: coeff = 32'h00000000;
    endcase
  end

endmodule