`timescale 1ns/1ps

module bandpass_fir #(
    parameter DATA_W  = 20,
    parameter TAP_CNT = 101,
    parameter GAIN_W  = 4
) (
    input                       clk,
    input                       rst,
    input                       valid_in,
    input      [DATA_W-1:0]     data_in,
    output                      valid_out,
    output     [DATA_W+GAIN_W-1:0] data_out
);

    localparam OUT_W = DATA_W + GAIN_W;

    reg signed [DATA_W-1:0] sample_delay [0:TAP_CNT-1];
    reg                     valid_reg;
    reg signed [OUT_W-1:0]  data_reg;

    wire signed [DATA_W-1:0] signed_sample;
    wire signed [63:0]       mac_sum;
    wire signed [OUT_W-1:0]  scaled_sample;

    integer i;

    bandpass_input_cast #(
        .DATA_W(DATA_W)
    ) u_input_cast (
        .data_in(data_in),
        .sample_out(signed_sample)
    );

    bandpass_mac_101 #(
        .DATA_W(DATA_W),
        .TAP_CNT(TAP_CNT)
    ) u_mac (
        .x0(sample_delay[0]),   .x1(sample_delay[1]),   .x2(sample_delay[2]),
        .x3(sample_delay[3]),   .x4(sample_delay[4]),   .x5(sample_delay[5]),
        .x6(sample_delay[6]),   .x7(sample_delay[7]),   .x8(sample_delay[8]),
        .x9(sample_delay[9]),   .x10(sample_delay[10]), .x11(sample_delay[11]),
        .x12(sample_delay[12]), .x13(sample_delay[13]), .x14(sample_delay[14]),
        .x15(sample_delay[15]), .x16(sample_delay[16]), .x17(sample_delay[17]),
        .x18(sample_delay[18]), .x19(sample_delay[19]), .x20(sample_delay[20]),
        .x21(sample_delay[21]), .x22(sample_delay[22]), .x23(sample_delay[23]),
        .x24(sample_delay[24]), .x25(sample_delay[25]), .x26(sample_delay[26]),
        .x27(sample_delay[27]), .x28(sample_delay[28]), .x29(sample_delay[29]),
        .x30(sample_delay[30]), .x31(sample_delay[31]), .x32(sample_delay[32]),
        .x33(sample_delay[33]), .x34(sample_delay[34]), .x35(sample_delay[35]),
        .x36(sample_delay[36]), .x37(sample_delay[37]), .x38(sample_delay[38]),
        .x39(sample_delay[39]), .x40(sample_delay[40]), .x41(sample_delay[41]),
        .x42(sample_delay[42]), .x43(sample_delay[43]), .x44(sample_delay[44]),
        .x45(sample_delay[45]), .x46(sample_delay[46]), .x47(sample_delay[47]),
        .x48(sample_delay[48]), .x49(sample_delay[49]), .x50(sample_delay[50]),
        .x51(sample_delay[51]), .x52(sample_delay[52]), .x53(sample_delay[53]),
        .x54(sample_delay[54]), .x55(sample_delay[55]), .x56(sample_delay[56]),
        .x57(sample_delay[57]), .x58(sample_delay[58]), .x59(sample_delay[59]),
        .x60(sample_delay[60]), .x61(sample_delay[61]), .x62(sample_delay[62]),
        .x63(sample_delay[63]), .x64(sample_delay[64]), .x65(sample_delay[65]),
        .x66(sample_delay[66]), .x67(sample_delay[67]), .x68(sample_delay[68]),
        .x69(sample_delay[69]), .x70(sample_delay[70]), .x71(sample_delay[71]),
        .x72(sample_delay[72]), .x73(sample_delay[73]), .x74(sample_delay[74]),
        .x75(sample_delay[75]), .x76(sample_delay[76]), .x77(sample_delay[77]),
        .x78(sample_delay[78]), .x79(sample_delay[79]), .x80(sample_delay[80]),
        .x81(sample_delay[81]), .x82(sample_delay[82]), .x83(sample_delay[83]),
        .x84(sample_delay[84]), .x85(sample_delay[85]), .x86(sample_delay[86]),
        .x87(sample_delay[87]), .x88(sample_delay[88]), .x89(sample_delay[89]),
        .x90(sample_delay[90]), .x91(sample_delay[91]), .x92(sample_delay[92]),
        .x93(sample_delay[93]), .x94(sample_delay[94]), .x95(sample_delay[95]),
        .x96(sample_delay[96]), .x97(sample_delay[97]), .x98(sample_delay[98]),
        .x99(sample_delay[99]), .x100(sample_delay[100]),
        .sum_out(mac_sum)
    );

    bandpass_q15_normalize #(
        .OUT_W(OUT_W)
    ) u_normalize (
        .sum_in(mac_sum),
        .data_out(scaled_sample)
    );

    always @(posedge clk) begin
        if (rst) begin
            for (i = 0; i < TAP_CNT; i = i + 1)
                sample_delay[i] <= {DATA_W{1'b0}};
            valid_reg <= 1'b0;
            data_reg  <= {OUT_W{1'b0}};
        end else begin
            valid_reg <= valid_in;
            if (valid_in) begin
                sample_delay[0] <= signed_sample;
                for (i = 1; i < TAP_CNT; i = i + 1)
                    sample_delay[i] <= sample_delay[i-1];
                data_reg <= scaled_sample;
            end else begin
                data_reg <= scaled_sample;
            end
        end
    end

    assign valid_out = valid_reg;
    assign data_out  = data_reg;

endmodule