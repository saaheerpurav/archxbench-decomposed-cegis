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
    output                      valid_out,
    output     [DATA_W+GAIN_W-1:0] data_out
);

    localparam OUT_W = DATA_W + GAIN_W;
    localparam ACC_W = 64;
    localparam COEFF_W = 16;

    reg signed [DATA_W-1:0] delay_line [0:TAP_CNT-2];
    reg                     valid_out_r;
    reg signed [OUT_W-1:0]  data_out_r;

    wire signed [TAP_CNT*DATA_W-1:0]  sample_window;
    wire signed [TAP_CNT*COEFF_W-1:0] coeff_vector;
    wire signed [ACC_W-1:0]           mac_accum;
    wire signed [OUT_W-1:0]           scaled_result;

    integer i;

    highpass_fir_tap_window #(
        .DATA_W(DATA_W),
        .TAP_CNT(TAP_CNT)
    ) u_tap_window (
        .data_in(data_in),
        .delay_0(delay_line[0]),
        .delay_1(delay_line[1]),
        .delay_2(delay_line[2]),
        .delay_3(delay_line[3]),
        .delay_4(delay_line[4]),
        .delay_5(delay_line[5]),
        .delay_6(delay_line[6]),
        .delay_7(delay_line[7]),
        .delay_8(delay_line[8]),
        .delay_9(delay_line[9]),
        .delay_10(delay_line[10]),
        .delay_11(delay_line[11]),
        .delay_12(delay_line[12]),
        .delay_13(delay_line[13]),
        .delay_14(delay_line[14]),
        .delay_15(delay_line[15]),
        .delay_16(delay_line[16]),
        .delay_17(delay_line[17]),
        .delay_18(delay_line[18]),
        .delay_19(delay_line[19]),
        .delay_20(delay_line[20]),
        .delay_21(delay_line[21]),
        .delay_22(delay_line[22]),
        .delay_23(delay_line[23]),
        .delay_24(delay_line[24]),
        .delay_25(delay_line[25]),
        .delay_26(delay_line[26]),
        .delay_27(delay_line[27]),
        .delay_28(delay_line[28]),
        .delay_29(delay_line[29]),
        .delay_30(delay_line[30]),
        .delay_31(delay_line[31]),
        .delay_32(delay_line[32]),
        .delay_33(delay_line[33]),
        .delay_34(delay_line[34]),
        .delay_35(delay_line[35]),
        .delay_36(delay_line[36]),
        .delay_37(delay_line[37]),
        .delay_38(delay_line[38]),
        .delay_39(delay_line[39]),
        .delay_40(delay_line[40]),
        .delay_41(delay_line[41]),
        .delay_42(delay_line[42]),
        .delay_43(delay_line[43]),
        .delay_44(delay_line[44]),
        .delay_45(delay_line[45]),
        .delay_46(delay_line[46]),
        .delay_47(delay_line[47]),
        .delay_48(delay_line[48]),
        .delay_49(delay_line[49]),
        .delay_50(delay_line[50]),
        .delay_51(delay_line[51]),
        .delay_52(delay_line[52]),
        .delay_53(delay_line[53]),
        .delay_54(delay_line[54]),
        .delay_55(delay_line[55]),
        .delay_56(delay_line[56]),
        .delay_57(delay_line[57]),
        .delay_58(delay_line[58]),
        .delay_59(delay_line[59]),
        .delay_60(delay_line[60]),
        .delay_61(delay_line[61]),
        .delay_62(delay_line[62]),
        .delay_63(delay_line[63]),
        .delay_64(delay_line[64]),
        .delay_65(delay_line[65]),
        .delay_66(delay_line[66]),
        .delay_67(delay_line[67]),
        .delay_68(delay_line[68]),
        .delay_69(delay_line[69]),
        .delay_70(delay_line[70]),
        .delay_71(delay_line[71]),
        .delay_72(delay_line[72]),
        .delay_73(delay_line[73]),
        .delay_74(delay_line[74]),
        .delay_75(delay_line[75]),
        .delay_76(delay_line[76]),
        .delay_77(delay_line[77]),
        .delay_78(delay_line[78]),
        .delay_79(delay_line[79]),
        .delay_80(delay_line[80]),
        .delay_81(delay_line[81]),
        .delay_82(delay_line[82]),
        .delay_83(delay_line[83]),
        .delay_84(delay_line[84]),
        .delay_85(delay_line[85]),
        .delay_86(delay_line[86]),
        .delay_87(delay_line[87]),
        .delay_88(delay_line[88]),
        .delay_89(delay_line[89]),
        .delay_90(delay_line[90]),
        .delay_91(delay_line[91]),
        .delay_92(delay_line[92]),
        .delay_93(delay_line[93]),
        .delay_94(delay_line[94]),
        .delay_95(delay_line[95]),
        .delay_96(delay_line[96]),
        .delay_97(delay_line[97]),
        .delay_98(delay_line[98]),
        .delay_99(delay_line[99]),
        .sample_window(sample_window)
    );

    highpass_fir_coeff_rom #(
        .TAP_CNT(TAP_CNT),
        .COEFF_W(COEFF_W)
    ) u_coeff_rom (
        .coeff_vector(coeff_vector)
    );

    highpass_fir_mac #(
        .DATA_W(DATA_W),
        .TAP_CNT(TAP_CNT),
        .COEFF_W(COEFF_W),
        .ACC_W(ACC_W)
    ) u_mac (
        .sample_window(sample_window),
        .coeff_vector(coeff_vector),
        .accum(mac_accum)
    );

    highpass_fir_q15_scale #(
        .ACC_W(ACC_W),
        .OUT_W(OUT_W)
    ) u_scale (
        .accum(mac_accum),
        .data_out(scaled_result)
    );

    always @(posedge clk) begin
        if (rst) begin
            valid_out_r <= 1'b0;
            data_out_r  <= {OUT_W{1'b0}};
            for (i = 0; i < TAP_CNT-1; i = i + 1)
                delay_line[i] <= {DATA_W{1'b0}};
        end else begin
            valid_out_r <= valid_in;

            if (valid_in) begin
                data_out_r <= scaled_result;
                delay_line[0] <= $signed(data_in);
                for (i = 1; i < TAP_CNT-1; i = i + 1)
                    delay_line[i] <= delay_line[i-1];
            end
        end
    end

    assign valid_out = valid_out_r;
    assign data_out  = data_out_r;

endmodule