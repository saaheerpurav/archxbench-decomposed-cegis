`timescale 1ns/1ps

module highpass_fir #(
    parameter DATA_W  = 20,
    parameter TAP_CNT = 101,
    parameter GAIN_W  = 4
) (
    input                       clk,
    input                       rst,
    input                       valid_in,
    input      [DATA_W-1:0]     data_in,
    output reg                  valid_out,
    output reg [DATA_W+GAIN_W-1:0] data_out
);
    localparam OUT_W = DATA_W + GAIN_W;
    localparam ACC_W = 64;

    reg signed [DATA_W-1:0] delay_line [0:TAP_CNT-1];
    integer i;

    wire signed [DATA_W-1:0] signed_data_in;
    wire signed [ACC_W-1:0] mac_accum;
    wire signed [OUT_W-1:0] normalized_out;

    assign signed_data_in = data_in;

    highpass_fir_mac #(
        .DATA_W(DATA_W),
        .TAP_CNT(TAP_CNT),
        .ACC_W(ACC_W)
    ) u_mac (
        .sample_in(signed_data_in),
        .d0(delay_line[0]),   .d1(delay_line[1]),   .d2(delay_line[2]),   .d3(delay_line[3]),
        .d4(delay_line[4]),   .d5(delay_line[5]),   .d6(delay_line[6]),   .d7(delay_line[7]),
        .d8(delay_line[8]),   .d9(delay_line[9]),   .d10(delay_line[10]), .d11(delay_line[11]),
        .d12(delay_line[12]), .d13(delay_line[13]), .d14(delay_line[14]), .d15(delay_line[15]),
        .d16(delay_line[16]), .d17(delay_line[17]), .d18(delay_line[18]), .d19(delay_line[19]),
        .d20(delay_line[20]), .d21(delay_line[21]), .d22(delay_line[22]), .d23(delay_line[23]),
        .d24(delay_line[24]), .d25(delay_line[25]), .d26(delay_line[26]), .d27(delay_line[27]),
        .d28(delay_line[28]), .d29(delay_line[29]), .d30(delay_line[30]), .d31(delay_line[31]),
        .d32(delay_line[32]), .d33(delay_line[33]), .d34(delay_line[34]), .d35(delay_line[35]),
        .d36(delay_line[36]), .d37(delay_line[37]), .d38(delay_line[38]), .d39(delay_line[39]),
        .d40(delay_line[40]), .d41(delay_line[41]), .d42(delay_line[42]), .d43(delay_line[43]),
        .d44(delay_line[44]), .d45(delay_line[45]), .d46(delay_line[46]), .d47(delay_line[47]),
        .d48(delay_line[48]), .d49(delay_line[49]), .d50(delay_line[50]), .d51(delay_line[51]),
        .d52(delay_line[52]), .d53(delay_line[53]), .d54(delay_line[54]), .d55(delay_line[55]),
        .d56(delay_line[56]), .d57(delay_line[57]), .d58(delay_line[58]), .d59(delay_line[59]),
        .d60(delay_line[60]), .d61(delay_line[61]), .d62(delay_line[62]), .d63(delay_line[63]),
        .d64(delay_line[64]), .d65(delay_line[65]), .d66(delay_line[66]), .d67(delay_line[67]),
        .d68(delay_line[68]), .d69(delay_line[69]), .d70(delay_line[70]), .d71(delay_line[71]),
        .d72(delay_line[72]), .d73(delay_line[73]), .d74(delay_line[74]), .d75(delay_line[75]),
        .d76(delay_line[76]), .d77(delay_line[77]), .d78(delay_line[78]), .d79(delay_line[79]),
        .d80(delay_line[80]), .d81(delay_line[81]), .d82(delay_line[82]), .d83(delay_line[83]),
        .d84(delay_line[84]), .d85(delay_line[85]), .d86(delay_line[86]), .d87(delay_line[87]),
        .d88(delay_line[88]), .d89(delay_line[89]), .d90(delay_line[90]), .d91(delay_line[91]),
        .d92(delay_line[92]), .d93(delay_line[93]), .d94(delay_line[94]), .d95(delay_line[95]),
        .d96(delay_line[96]), .d97(delay_line[97]), .d98(delay_line[98]), .d99(delay_line[99]),
        .accum(mac_accum)
    );

    highpass_fir_normalize #(
        .ACC_W(ACC_W),
        .OUT_W(OUT_W)
    ) u_normalize (
        .accum(mac_accum),
        .data_out(normalized_out)
    );

    always @(posedge clk) begin
        if (rst) begin
            valid_out <= 1'b0;
            data_out  <= {OUT_W{1'b0}};
            for (i = 0; i < TAP_CNT; i = i + 1)
                delay_line[i] <= {DATA_W{1'b0}};
        end else begin
            valid_out <= valid_in;

            if (valid_in) begin
                data_out <= normalized_out;
                delay_line[0] <= signed_data_in;
                for (i = 1; i < TAP_CNT; i = i + 1)
                    delay_line[i] <= delay_line[i-1];
            end
        end
    end
endmodule