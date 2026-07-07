`timescale 1ns/1ps

module fp_hp_coeff_rom (
    input      [7:0]  index,
    output reg [31:0] coeff
);
    always @* begin
        case (index)
            8'd0:  coeff = 32'ha1381601;
            8'd1:  coeff = 32'hba9dbdb2;
            8'd2:  coeff = 32'hbb36c8a9;
            8'd3:  coeff = 32'hbb8ac191;
            8'd4:  coeff = 32'hbb816a82;
            8'd5:  coeff = 32'h22325551;
            8'd6:  coeff = 32'h3c07824b;
            8'd7:  coeff = 32'h3c987e0d;
            8'd8:  coeff = 32'h3cd058cf;
            8'd9:  coeff = 32'h3cae415b;
            8'd10: coeff = 32'ha2dd7a7a;
            8'd11: coeff = 32'hbd226db2;
            8'd12: coeff = 32'hbdbc821d;
            8'd13: coeff = 32'hbe14d580;
            8'd14: coeff = 32'hbe3da98f;
            8'd15: coeff = 32'h3f4ccccd;
            8'd16: coeff = 32'hbe3da98f;
            8'd17: coeff = 32'hbe14d580;
            8'd18: coeff = 32'hbdbc821d;
            8'd19: coeff = 32'hbd226db2;
            8'd20: coeff = 32'ha2dd7a7a;
            8'd21: coeff = 32'h3cae415b;
            8'd22: coeff = 32'h3cd058cf;
            8'd23: coeff = 32'h3c987e0d;
            8'd24: coeff = 32'h3c07824b;
            8'd25: coeff = 32'h22325551;
            8'd26: coeff = 32'hbb816a82;
            8'd27: coeff = 32'hbb8ac191;
            8'd28: coeff = 32'hbb36c8a9;
            8'd29: coeff = 32'hba9dbdb2;
            8'd30: coeff = 32'ha1381601;
            default: coeff = 32'h00000000;
        endcase
    end
endmodule