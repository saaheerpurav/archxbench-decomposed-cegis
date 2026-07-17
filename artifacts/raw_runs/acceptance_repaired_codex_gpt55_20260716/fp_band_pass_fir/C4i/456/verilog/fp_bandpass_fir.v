`timescale 1ns/1ps

module fp_bandpass_fir #(
    parameter TAP_CNT = 101
) (
    input wire clk,
    input wire rst,
    input wire valid_in,
    input wire [31:0] data_in,
    output wire valid_out,
    output wire [31:0] data_out
);

  localparam QW = 64;

  reg [QW-1:0] sample_hist [0:TAP_CNT-1];
  reg valid_r;
  integer i;

  wire signed [QW-1:0] sample_q;
  wire signed [QW-1:0] fir_q;
  wire [31:0] fir_fp;

  fp32_to_q32_32 u_input_convert (
    .fp(data_in),
    .q(sample_q)
  );

  q32_32_fir_mac #(
    .TAP_CNT(TAP_CNT)
  ) u_mac (
    .x0(sample_hist[0]),   .x1(sample_hist[1]),   .x2(sample_hist[2]),
    .x3(sample_hist[3]),   .x4(sample_hist[4]),   .x5(sample_hist[5]),
    .x6(sample_hist[6]),   .x7(sample_hist[7]),   .x8(sample_hist[8]),
    .x9(sample_hist[9]),   .x10(sample_hist[10]), .x11(sample_hist[11]),
    .x12(sample_hist[12]), .x13(sample_hist[13]), .x14(sample_hist[14]),
    .x15(sample_hist[15]), .x16(sample_hist[16]), .x17(sample_hist[17]),
    .x18(sample_hist[18]), .x19(sample_hist[19]), .x20(sample_hist[20]),
    .x21(sample_hist[21]), .x22(sample_hist[22]), .x23(sample_hist[23]),
    .x24(sample_hist[24]), .x25(sample_hist[25]), .x26(sample_hist[26]),
    .x27(sample_hist[27]), .x28(sample_hist[28]), .x29(sample_hist[29]),
    .x30(sample_hist[30]), .x31(sample_hist[31]), .x32(sample_hist[32]),
    .x33(sample_hist[33]), .x34(sample_hist[34]), .x35(sample_hist[35]),
    .x36(sample_hist[36]), .x37(sample_hist[37]), .x38(sample_hist[38]),
    .x39(sample_hist[39]), .x40(sample_hist[40]), .x41(sample_hist[41]),
    .x42(sample_hist[42]), .x43(sample_hist[43]), .x44(sample_hist[44]),
    .x45(sample_hist[45]), .x46(sample_hist[46]), .x47(sample_hist[47]),
    .x48(sample_hist[48]), .x49(sample_hist[49]), .x50(sample_hist[50]),
    .x51(sample_hist[51]), .x52(sample_hist[52]), .x53(sample_hist[53]),
    .x54(sample_hist[54]), .x55(sample_hist[55]), .x56(sample_hist[56]),
    .x57(sample_hist[57]), .x58(sample_hist[58]), .x59(sample_hist[59]),
    .x60(sample_hist[60]), .x61(sample_hist[61]), .x62(sample_hist[62]),
    .x63(sample_hist[63]), .x64(sample_hist[64]), .x65(sample_hist[65]),
    .x66(sample_hist[66]), .x67(sample_hist[67]), .x68(sample_hist[68]),
    .x69(sample_hist[69]), .x70(sample_hist[70]), .x71(sample_hist[71]),
    .x72(sample_hist[72]), .x73(sample_hist[73]), .x74(sample_hist[74]),
    .x75(sample_hist[75]), .x76(sample_hist[76]), .x77(sample_hist[77]),
    .x78(sample_hist[78]), .x79(sample_hist[79]), .x80(sample_hist[80]),
    .x81(sample_hist[81]), .x82(sample_hist[82]), .x83(sample_hist[83]),
    .x84(sample_hist[84]), .x85(sample_hist[85]), .x86(sample_hist[86]),
    .x87(sample_hist[87]), .x88(sample_hist[88]), .x89(sample_hist[89]),
    .x90(sample_hist[90]), .x91(sample_hist[91]), .x92(sample_hist[92]),
    .x93(sample_hist[93]), .x94(sample_hist[94]), .x95(sample_hist[95]),
    .x96(sample_hist[96]), .x97(sample_hist[97]), .x98(sample_hist[98]),
    .x99(sample_hist[99]), .x100(sample_hist[100]),
    .y(fir_q)
  );

  q32_32_to_fp32 u_output_convert (
    .q(fir_q),
    .fp(fir_fp)
  );

  always @(posedge clk) begin
    if (rst) begin
      valid_r <= 1'b0;
      for (i = 0; i < TAP_CNT; i = i + 1)
        sample_hist[i] <= {QW{1'b0}};
    end else begin
      valid_r <= valid_in;
      if (valid_in) begin
        for (i = TAP_CNT-1; i > 0; i = i - 1)
          sample_hist[i] <= sample_hist[i-1];
        sample_hist[0] <= sample_q;
      end
    end
  end

  assign valid_out = valid_r;
  assign data_out = fir_fp;

endmodule