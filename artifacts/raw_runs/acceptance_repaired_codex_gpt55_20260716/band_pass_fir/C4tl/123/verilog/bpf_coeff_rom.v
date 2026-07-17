`timescale 1ns/1ps

module bpf_coeff_rom (
    input      [7:0] tap_index,
    output reg signed [15:0] coeff
);

    always @* begin
        case (tap_index)
            8'd0:   coeff = 16'sd16;
            8'd1:   coeff = 16'sd10;
            8'd2:   coeff = 16'sd6;
            8'd3:   coeff = 16'sd2;
            8'd4:   coeff = 16'sd0;
            8'd5:   coeff = 16'sd1;
            8'd6:   coeff = 16'sd5;
            8'd7:   coeff = 16'sd13;
            8'd8:   coeff = 16'sd26;
            8'd9:   coeff = 16'sd42;
            8'd10:  coeff = 16'sd59;
            8'd11:  coeff = 16'sd77;
            8'd12:  coeff = 16'sd90;
            8'd13:  coeff = 16'sd97;
            8'd14:  coeff = 16'sd93;
            8'd15:  coeff = 16'sd77;
            8'd16:  coeff = 16'sd47;
            8'd17:  coeff = 16'sd5;
            8'd18:  coeff = -16'sd45;
            8'd19:  coeff = -16'sd99;
            8'd20:  coeff = -16'sd149;
            8'd21:  coeff = -16'sd187;
            8'd22:  coeff = -16'sd207;
            8'd23:  coeff = -16'sd204;
            8'd24:  coeff = -16'sd178;
            8'd25:  coeff = -16'sd132;
            8'd26:  coeff = -16'sd73;
            8'd27:  coeff = -16'sd14;
            8'd28:  coeff = 16'sd31;
            8'd29:  coeff = 16'sd46;
            8'd30:  coeff = 16'sd16;
            8'd31:  coeff = -16'sd67;
            8'd32:  coeff = -16'sd208;
            8'd33:  coeff = -16'sd403;
            8'd34:  coeff = -16'sd638;
            8'd35:  coeff = -16'sd891;
            8'd36:  coeff = -16'sd1134;
            8'd37:  coeff = -16'sd1333;
            8'd38:  coeff = -16'sd1455;
            8'd39:  coeff = -16'sd1471;
            8'd40:  coeff = -16'sd1359;
            8'd41:  coeff = -16'sd1111;
            8'd42:  coeff = -16'sd730;
            8'd43:  coeff = -16'sd235;
            8'd44:  coeff = 16'sd341;
            8'd45:  coeff = 16'sd955;
            8'd46:  coeff = 16'sd1555;
            8'd47:  coeff = 16'sd2091;
            8'd48:  coeff = 16'sd2513;
            8'd49:  coeff = 16'sd2784;
            8'd50:  coeff = 16'sd2877;
            8'd51:  coeff = 16'sd2784;
            8'd52:  coeff = 16'sd2513;
            8'd53:  coeff = 16'sd2091;
            8'd54:  coeff = 16'sd1555;
            8'd55:  coeff = 16'sd955;
            8'd56:  coeff = 16'sd341;
            8'd57:  coeff = -16'sd235;
            8'd58:  coeff = -16'sd730;
            8'd59:  coeff = -16'sd1111;
            8'd60:  coeff = -16'sd1359;
            8'd61:  coeff = -16'sd1471;
            8'd62:  coeff = -16'sd1455;
            8'd63:  coeff = -16'sd1333;
            8'd64:  coeff = -16'sd1134;
            8'd65:  coeff = -16'sd891;
            8'd66:  coeff = -16'sd638;
            8'd67:  coeff = -16'sd403;
            8'd68:  coeff = -16'sd208;
            8'd69:  coeff = -16'sd67;
            8'd70:  coeff = 16'sd16;
            8'd71:  coeff = 16'sd46;
            8'd72:  coeff = 16'sd31;
            8'd73:  coeff = -16'sd14;
            8'd74:  coeff = -16'sd73;
            8'd75:  coeff = -16'sd132;
            8'd76:  coeff = -16'sd178;
            8'd77:  coeff = -16'sd204;
            8'd78:  coeff = -16'sd207;
            8'd79:  coeff = -16'sd187;
            8'd80:  coeff = -16'sd149;
            8'd81:  coeff = -16'sd99;
            8'd82:  coeff = -16'sd45;
            8'd83:  coeff = 16'sd5;
            8'd84:  coeff = 16'sd47;
            8'd85:  coeff = 16'sd77;
            8'd86:  coeff = 16'sd93;
            8'd87:  coeff = 16'sd97;
            8'd88:  coeff = 16'sd90;
            8'd89:  coeff = 16'sd77;
            8'd90:  coeff = 16'sd59;
            8'd91:  coeff = 16'sd42;
            8'd92:  coeff = 16'sd26;
            8'd93:  coeff = 16'sd13;
            8'd94:  coeff = 16'sd5;
            8'd95:  coeff = 16'sd1;
            8'd96:  coeff = 16'sd0;
            8'd97:  coeff = 16'sd2;
            8'd98:  coeff = 16'sd6;
            8'd99:  coeff = 16'sd10;
            8'd100: coeff = 16'sd16;
            default: coeff = 16'sd0;
        endcase
    end

endmodule