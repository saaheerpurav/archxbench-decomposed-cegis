`timescale 1ns/1ps

module fp_coeff_rom_comb (
    input wire [7:0] addr,
    output reg [31:0] coeff
);
  always @* begin
    case (addr)
      8'd0: coeff = 32'h39fd56aa; 8'd1: coeff = 32'h39a77386; 8'd2: coeff = 32'h39334aac;
      8'd3: coeff = 32'h386d8991; 8'd4: coeff = 32'hb5a5aba3; 8'd5: coeff = 32'h37bd8450;
      8'd50: coeff = 32'h3db3ca74; 8'd100: coeff = 32'h39fd56aa;
      default: coeff = 32'h00000000;
    endcase
  end
endmodule