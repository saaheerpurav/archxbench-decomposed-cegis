`timescale 1ns/1ps

module fp_highpass_fir #(
    parameter TAP_CNT = 101
) (
    input wire clk,
    input wire rst,
    input wire valid_in,
    input wire [31:0] data_in,
    output wire valid_out,
    output wire [31:0] data_out
);

  reg [31:0] sample_delay [0:TAP_CNT-1];
  reg [31:0] out_reg;
  reg valid_reg;
  integer i;

  wire [TAP_CNT*32-1:0] sample_bus;
  wire [TAP_CNT*32-1:0] coeff_bus;
  wire [31:0] fir_result;

  fp_fir_sample_packer #(.TAP_CNT(TAP_CNT)) u_sample_packer (
    .sample_bus(sample_bus),
    .s0(sample_delay[0]), .s1(sample_delay[1]), .s2(sample_delay[2]),
    .s3(sample_delay[3]), .s4(sample_delay[4]), .s5(sample_delay[5]),
    .s6(sample_delay[6]), .s7(sample_delay[7]), .s8(sample_delay[8]),
    .s9(sample_delay[9]), .s10(sample_delay[10]), .s11(sample_delay[11]),
    .s12(sample_delay[12]), .s13(sample_delay[13]), .s14(sample_delay[14]),
    .s15(sample_delay[15]), .s16(sample_delay[16]), .s17(sample_delay[17]),
    .s18(sample_delay[18]), .s19(sample_delay[19]), .s20(sample_delay[20]),
    .s21(sample_delay[21]), .s22(sample_delay[22]), .s23(sample_delay[23]),
    .s24(sample_delay[24]), .s25(sample_delay[25]), .s26(sample_delay[26]),
    .s27(sample_delay[27]), .s28(sample_delay[28]), .s29(sample_delay[29]),
    .s30(sample_delay[30]), .s31(sample_delay[31]), .s32(sample_delay[32]),
    .s33(sample_delay[33]), .s34(sample_delay[34]), .s35(sample_delay[35]),
    .s36(sample_delay[36]), .s37(sample_delay[37]), .s38(sample_delay[38]),
    .s39(sample_delay[39]), .s40(sample_delay[40]), .s41(sample_delay[41]),
    .s42(sample_delay[42]), .s43(sample_delay[43]), .s44(sample_delay[44]),
    .s45(sample_delay[45]), .s46(sample_delay[46]), .s47(sample_delay[47]),
    .s48(sample_delay[48]), .s49(sample_delay[49]), .s50(sample_delay[50]),
    .s51(sample_delay[51]), .s52(sample_delay[52]), .s53(sample_delay[53]),
    .s54(sample_delay[54]), .s55(sample_delay[55]), .s56(sample_delay[56]),
    .s57(sample_delay[57]), .s58(sample_delay[58]), .s59(sample_delay[59]),
    .s60(sample_delay[60]), .s61(sample_delay[61]), .s62(sample_delay[62]),
    .s63(sample_delay[63]), .s64(sample_delay[64]), .s65(sample_delay[65]),
    .s66(sample_delay[66]), .s67(sample_delay[67]), .s68(sample_delay[68]),
    .s69(sample_delay[69]), .s70(sample_delay[70]), .s71(sample_delay[71]),
    .s72(sample_delay[72]), .s73(sample_delay[73]), .s74(sample_delay[74]),
    .s75(sample_delay[75]), .s76(sample_delay[76]), .s77(sample_delay[77]),
    .s78(sample_delay[78]), .s79(sample_delay[79]), .s80(sample_delay[80]),
    .s81(sample_delay[81]), .s82(sample_delay[82]), .s83(sample_delay[83]),
    .s84(sample_delay[84]), .s85(sample_delay[85]), .s86(sample_delay[86]),
    .s87(sample_delay[87]), .s88(sample_delay[88]), .s89(sample_delay[89]),
    .s90(sample_delay[90]), .s91(sample_delay[91]), .s92(sample_delay[92]),
    .s93(sample_delay[93]), .s94(sample_delay[94]), .s95(sample_delay[95]),
    .s96(sample_delay[96]), .s97(sample_delay[97]), .s98(sample_delay[98]),
    .s99(sample_delay[99]), .s100(sample_delay[100])
  );

  fp_highpass_coeff_rom #(.TAP_CNT(TAP_CNT)) u_coeff_rom (
    .coeff_bus(coeff_bus)
  );

  fp_fir_real_mac #(.TAP_CNT(TAP_CNT)) u_mac (
    .sample_bus(sample_bus),
    .coeff_bus(coeff_bus),
    .new_sample(data_in),
    .result(fir_result)
  );

  assign valid_out = valid_reg;
  assign data_out = out_reg;

  always @(posedge clk) begin
    if (rst) begin
      for (i = 0; i < TAP_CNT; i = i + 1)
        sample_delay[i] <= 32'h00000000;
      out_reg <= 32'h00000000;
      valid_reg <= 1'b0;
    end else begin
      valid_reg <= valid_in;
      if (valid_in) begin
        out_reg <= fir_result;
        sample_delay[0] <= data_in;
        for (i = 1; i < TAP_CNT; i = i + 1)
          sample_delay[i] <= sample_delay[i-1];
      end
    end
  end

endmodule