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
    localparam ACC_W = 64;

    reg signed [DATA_W-1:0] delay_line [0:TAP_CNT-1];
    reg signed [OUT_W-1:0]  data_out_r;
    reg                     valid_out_r;

    wire signed [DATA_W-1:0] data_in_s;
    wire signed [ACC_W-1:0]  mac_sum;
    wire signed [OUT_W-1:0]  scaled_out;

    integer i;

    assign data_in_s = data_in;
    assign valid_out = valid_out_r;
    assign data_out  = data_out_r;

    fir_mac_101 #(
        .DATA_W(DATA_W),
        .TAP_CNT(TAP_CNT),
        .ACC_W(ACC_W)
    ) u_mac (
        .new_sample(data_in_s),
        .x0(delay_line[0]),   .x1(delay_line[1]),   .x2(delay_line[2]),   .x3(delay_line[3]),
        .x4(delay_line[4]),   .x5(delay_line[5]),   .x6(delay_line[6]),   .x7(delay_line[7]),
        .x8(delay_line[8]),   .x9(delay_line[9]),   .x10(delay_line[10]), .x11(delay_line[11]),
        .x12(delay_line[12]), .x13(delay_line[13]), .x14(delay_line[14]), .x15(delay_line[15]),
        .x16(delay_line[16]), .x17(delay_line[17]), .x18(delay_line[18]), .x19(delay_line[19]),
        .x20(delay_line[20]), .x21(delay_line[21]), .x22(delay_line[22]), .x23(delay_line[23]),
        .x24(delay_line[24]), .x25(delay_line[25]), .x26(delay_line[26]), .x27(delay_line[27]),
        .x28(delay_line[28]), .x29(delay_line[29]), .x30(delay_line[30]), .x31(delay_line[31]),
        .x32(delay_line[32]), .x33(delay_line[33]), .x34(delay_line[34]), .x35(delay_line[35]),
        .x36(delay_line[36]), .x37(delay_line[37]), .x38(delay_line[38]), .x39(delay_line[39]),
        .x40(delay_line[40]), .x41(delay_line[41]), .x42(delay_line[42]), .x43(delay_line[43]),
        .x44(delay_line[44]), .x45(delay_line[45]), .x46(delay_line[46]), .x47(delay_line[47]),
        .x48(delay_line[48]), .x49(delay_line[49]), .x50(delay_line[50]), .x51(delay_line[51]),
        .x52(delay_line[52]), .x53(delay_line[53]), .x54(delay_line[54]), .x55(delay_line[55]),
        .x56(delay_line[56]), .x57(delay_line[57]), .x58(delay_line[58]), .x59(delay_line[59]),
        .x60(delay_line[60]), .x61(delay_line[61]), .x62(delay_line[62]), .x63(delay_line[63]),
        .x64(delay_line[64]), .x65(delay_line[65]), .x66(delay_line[66]), .x67(delay_line[67]),
        .x68(delay_line[68]), .x69(delay_line[69]), .x70(delay_line[70]), .x71(delay_line[71]),
        .x72(delay_line[72]), .x73(delay_line[73]), .x74(delay_line[74]), .x75(delay_line[75]),
        .x76(delay_line[76]), .x77(delay_line[77]), .x78(delay_line[78]), .x79(delay_line[79]),
        .x80(delay_line[80]), .x81(delay_line[81]), .x82(delay_line[82]), .x83(delay_line[83]),
        .x84(delay_line[84]), .x85(delay_line[85]), .x86(delay_line[86]), .x87(delay_line[87]),
        .x88(delay_line[88]), .x89(delay_line[89]), .x90(delay_line[90]), .x91(delay_line[91]),
        .x92(delay_line[92]), .x93(delay_line[93]), .x94(delay_line[94]), .x95(delay_line[95]),
        .x96(delay_line[96]), .x97(delay_line[97]), .x98(delay_line[98]), .x99(delay_line[99]),
        .sum(mac_sum)
    );

    fir_q15_normalize #(
        .ACC_W(ACC_W),
        .OUT_W(OUT_W)
    ) u_norm (
        .acc_in(mac_sum),
        .data_out(scaled_out)
    );

    always @(posedge clk) begin
        if (rst) begin
            valid_out_r <= 1'b0;
            data_out_r  <= {OUT_W{1'b0}};
            for (i = 0; i < TAP_CNT; i = i + 1)
                delay_line[i] <= {DATA_W{1'b0}};
        end else begin
            valid_out_r <= valid_in;
            if (valid_in) begin
                data_out_r <= scaled_out;
                delay_line[0] <= data_in_s;
                for (i = 1; i < TAP_CNT; i = i + 1)
                    delay_line[i] <= delay_line[i-1];
            end
        end
    end
endmodule