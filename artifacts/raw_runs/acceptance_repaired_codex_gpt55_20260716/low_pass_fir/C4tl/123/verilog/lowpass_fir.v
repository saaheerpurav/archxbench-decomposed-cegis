`timescale 1ns/1ps

module lowpass_fir #(
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
    localparam PAIR_CNT = 50;

    reg signed [DATA_W-1:0] delay_line [0:99];
    reg                     valid_r;
    reg signed [OUT_W-1:0]  data_out_r;

    wire signed [DATA_W-1:0] sample [0:100];
    wire signed [DATA_W:0]   pair_sum [0:49];
    wire signed [31:0]       product [0:50];
    wire signed [ACC_W-1:0]  acc_sum;
    wire signed [OUT_W-1:0]  quantized;

    integer i;

    assign sample[0] = $signed(data_in);

    genvar si;
    generate
        for (si = 1; si < 101; si = si + 1) begin : g_samples
            assign sample[si] = delay_line[si-1];
        end
    endgenerate

    generate
        fir_pair_sum #(.DATA_W(DATA_W)) u_pair_sum_0  (.a(sample[0]),  .b(sample[100]), .sum(pair_sum[0]));
        fir_pair_sum #(.DATA_W(DATA_W)) u_pair_sum_1  (.a(sample[1]),  .b(sample[99]),  .sum(pair_sum[1]));
        fir_pair_sum #(.DATA_W(DATA_W)) u_pair_sum_2  (.a(sample[2]),  .b(sample[98]),  .sum(pair_sum[2]));
        fir_pair_sum #(.DATA_W(DATA_W)) u_pair_sum_3  (.a(sample[3]),  .b(sample[97]),  .sum(pair_sum[3]));
        fir_pair_sum #(.DATA_W(DATA_W)) u_pair_sum_4  (.a(sample[4]),  .b(sample[96]),  .sum(pair_sum[4]));
        fir_pair_sum #(.DATA_W(DATA_W)) u_pair_sum_5  (.a(sample[5]),  .b(sample[95]),  .sum(pair_sum[5]));
        fir_pair_sum #(.DATA_W(DATA_W)) u_pair_sum_6  (.a(sample[6]),  .b(sample[94]),  .sum(pair_sum[6]));
        fir_pair_sum #(.DATA_W(DATA_W)) u_pair_sum_7  (.a(sample[7]),  .b(sample[93]),  .sum(pair_sum[7]));
        fir_pair_sum #(.DATA_W(DATA_W)) u_pair_sum_8  (.a(sample[8]),  .b(sample[92]),  .sum(pair_sum[8]));
        fir_pair_sum #(.DATA_W(DATA_W)) u_pair_sum_9  (.a(sample[9]),  .b(sample[91]),  .sum(pair_sum[9]));
        fir_pair_sum #(.DATA_W(DATA_W)) u_pair_sum_10 (.a(sample[10]), .b(sample[90]),  .sum(pair_sum[10]));
        fir_pair_sum #(.DATA_W(DATA_W)) u_pair_sum_11 (.a(sample[11]), .b(sample[89]),  .sum(pair_sum[11]));
        fir_pair_sum #(.DATA_W(DATA_W)) u_pair_sum_12 (.a(sample[12]), .b(sample[88]),  .sum(pair_sum[12]));
        fir_pair_sum #(.DATA_W(DATA_W)) u_pair_sum_13 (.a(sample[13]), .b(sample[87]),  .sum(pair_sum[13]));
        fir_pair_sum #(.DATA_W(DATA_W)) u_pair_sum_14 (.a(sample[14]), .b(sample[86]),  .sum(pair_sum[14]));
        fir_pair_sum #(.DATA_W(DATA_W)) u_pair_sum_15 (.a(sample[15]), .b(sample[85]),  .sum(pair_sum[15]));
        fir_pair_sum #(.DATA_W(DATA_W)) u_pair_sum_16 (.a(sample[16]), .b(sample[84]),  .sum(pair_sum[16]));
        fir_pair_sum #(.DATA_W(DATA_W)) u_pair_sum_17 (.a(sample[17]), .b(sample[83]),  .sum(pair_sum[17]));
        fir_pair_sum #(.DATA_W(DATA_W)) u_pair_sum_18 (.a(sample[18]), .b(sample[82]),  .sum(pair_sum[18]));
        fir_pair_sum #(.DATA_W(DATA_W)) u_pair_sum_19 (.a(sample[19]), .b(sample[81]),  .sum(pair_sum[19]));
        fir_pair_sum #(.DATA_W(DATA_W)) u_pair_sum_20 (.a(sample[20]), .b(sample[80]),  .sum(pair_sum[20]));
        fir_pair_sum #(.DATA_W(DATA_W)) u_pair_sum_21 (.a(sample[21]), .b(sample[79]),  .sum(pair_sum[21]));
        fir_pair_sum #(.DATA_W(DATA_W)) u_pair_sum_22 (.a(sample[22]), .b(sample[78]),  .sum(pair_sum[22]));
        fir_pair_sum #(.DATA_W(DATA_W)) u_pair_sum_23 (.a(sample[23]), .b(sample[77]),  .sum(pair_sum[23]));
        fir_pair_sum #(.DATA_W(DATA_W)) u_pair_sum_24 (.a(sample[24]), .b(sample[76]),  .sum(pair_sum[24]));
        fir_pair_sum #(.DATA_W(DATA_W)) u_pair_sum_25 (.a(sample[25]), .b(sample[75]),  .sum(pair_sum[25]));
        fir_pair_sum #(.DATA_W(DATA_W)) u_pair_sum_26 (.a(sample[26]), .b(sample[74]),  .sum(pair_sum[26]));
        fir_pair_sum #(.DATA_W(DATA_W)) u_pair_sum_27 (.a(sample[27]), .b(sample[73]),  .sum(pair_sum[27]));
        fir_pair_sum #(.DATA_W(DATA_W)) u_pair_sum_28 (.a(sample[28]), .b(sample[72]),  .sum(pair_sum[28]));
        fir_pair_sum #(.DATA_W(DATA_W)) u_pair_sum_29 (.a(sample[29]), .b(sample[71]),  .sum(pair_sum[29]));
        fir_pair_sum #(.DATA_W(DATA_W)) u_pair_sum_30 (.a(sample[30]), .b(sample[70]),  .sum(pair_sum[30]));
        fir_pair_sum #(.DATA_W(DATA_W)) u_pair_sum_31 (.a(sample[31]), .b(sample[69]),  .sum(pair_sum[31]));
        fir_pair_sum #(.DATA_W(DATA_W)) u_pair_sum_32 (.a(sample[32]), .b(sample[68]),  .sum(pair_sum[32]));
        fir_pair_sum #(.DATA_W(DATA_W)) u_pair_sum_33 (.a(sample[33]), .b(sample[67]),  .sum(pair_sum[33]));
        fir_pair_sum #(.DATA_W(DATA_W)) u_pair_sum_34 (.a(sample[34]), .b(sample[66]),  .sum(pair_sum[34]));
        fir_pair_sum #(.DATA_W(DATA_W)) u_pair_sum_35 (.a(sample[35]), .b(sample[65]),  .sum(pair_sum[35]));
        fir_pair_sum #(.DATA_W(DATA_W)) u_pair_sum_36 (.a(sample[36]), .b(sample[64]),  .sum(pair_sum[36]));
        fir_pair_sum #(.DATA_W(DATA_W)) u_pair_sum_37 (.a(sample[37]), .b(sample[63]),  .sum(pair_sum[37]));
        fir_pair_sum #(.DATA_W(DATA_W)) u_pair_sum_38 (.a(sample[38]), .b(sample[62]),  .sum(pair_sum[38]));
        fir_pair_sum #(.DATA_W(DATA_W)) u_pair_sum_39 (.a(sample[39]), .b(sample[61]),  .sum(pair_sum[39]));
        fir_pair_sum #(.DATA_W(DATA_W)) u_pair_sum_40 (.a(sample[40]), .b(sample[60]),  .sum(pair_sum[40]));
        fir_pair_sum #(.DATA_W(DATA_W)) u_pair_sum_41 (.a(sample[41]), .b(sample[59]),  .sum(pair_sum[41]));
        fir_pair_sum #(.DATA_W(DATA_W)) u_pair_sum_42 (.a(sample[42]), .b(sample[58]),  .sum(pair_sum[42]));
        fir_pair_sum #(.DATA_W(DATA_W)) u_pair_sum_43 (.a(sample[43]), .b(sample[57]),  .sum(pair_sum[43]));
        fir_pair_sum #(.DATA_W(DATA_W)) u_pair_sum_44 (.a(sample[44]), .b(sample[56]),  .sum(pair_sum[44]));
        fir_pair_sum #(.DATA_W(DATA_W)) u_pair_sum_45 (.a(sample[45]), .b(sample[55]),  .sum(pair_sum[45]));
        fir_pair_sum #(.DATA_W(DATA_W)) u_pair_sum_46 (.a(sample[46]), .b(sample[54]),  .sum(pair_sum[46]));
        fir_pair_sum #(.DATA_W(DATA_W)) u_pair_sum_47 (.a(sample[47]), .b(sample[53]),  .sum(pair_sum[47]));
        fir_pair_sum #(.DATA_W(DATA_W)) u_pair_sum_48 (.a(sample[48]), .b(sample[52]),  .sum(pair_sum[48]));
        fir_pair_sum #(.DATA_W(DATA_W)) u_pair_sum_49 (.a(sample[49]), .b(sample[51]),  .sum(pair_sum[49]));
    endgenerate

    fir_product #(.IN_W(DATA_W+1), .COEFF(0))    u_prod_0  (.sample(pair_sum[0]),  .product(product[0]));
    fir_product #(.IN_W(DATA_W+1), .COEFF(-2))   u_prod_1  (.sample(pair_sum[1]),  .product(product[1]));
    fir_product #(.IN_W(DATA_W+1), .COEFF(-5))   u_prod_2  (.sample(pair_sum[2]),  .product(product[2]));
    fir_product #(.IN_W(DATA_W+1), .COEFF(-7))   u_prod_3  (.sample(pair_sum[3]),  .product(product[3]));
    fir_product #(.IN_W(DATA_W+1), .COEFF(-10))  u_prod_4  (.sample(pair_sum[4]),  .product(product[4]));
    fir_product #(.IN_W(DATA_W+1), .COEFF(-14))  u_prod_5  (.sample(pair_sum[5]),  .product(product[5]));
    fir_product #(.IN_W(DATA_W+1), .COEFF(-18))  u_prod_6  (.sample(pair_sum[6]),  .product(product[6]));
    fir_product #(.IN_W(DATA_W+1), .COEFF(-23))  u_prod_7  (.sample(pair_sum[7]),  .product(product[7]));
    fir_product #(.IN_W(DATA_W+1), .COEFF(-29))  u_prod_8  (.sample(pair_sum[8]),  .product(product[8]));
    fir_product #(.IN_W(DATA_W+1), .COEFF(-35))  u_prod_9  (.sample(pair_sum[9]),  .product(product[9]));
    fir_product #(.IN_W(DATA_W+1), .COEFF(-41))  u_prod_10 (.sample(pair_sum[10]), .product(product[10]));
    fir_product #(.IN_W(DATA_W+1), .COEFF(-49))  u_prod_11 (.sample(pair_sum[11]), .product(product[11]));
    fir_product #(.IN_W(DATA_W+1), .COEFF(-56))  u_prod_12 (.sample(pair_sum[12]), .product(product[12]));
    fir_product #(.IN_W(DATA_W+1), .COEFF(-63))  u_prod_13 (.sample(pair_sum[13]), .product(product[13]));
    fir_product #(.IN_W(DATA_W+1), .COEFF(-70))  u_prod_14 (.sample(pair_sum[14]), .product(product[14]));
    fir_product #(.IN_W(DATA_W+1), .COEFF(-76))  u_prod_15 (.sample(pair_sum[15]), .product(product[15]));
    fir_product #(.IN_W(DATA_W+1), .COEFF(-81))  u_prod_16 (.sample(pair_sum[16]), .product(product[16]));
    fir_product #(.IN_W(DATA_W+1), .COEFF(-85))  u_prod_17 (.sample(pair_sum[17]), .product(product[17]));
    fir_product #(.IN_W(DATA_W+1), .COEFF(-86))  u_prod_18 (.sample(pair_sum[18]), .product(product[18]));
    fir_product #(.IN_W(DATA_W+1), .COEFF(-85))  u_prod_19 (.sample(pair_sum[19]), .product(product[19]));
    fir_product #(.IN_W(DATA_W+1), .COEFF(-81))  u_prod_20 (.sample(pair_sum[20]), .product(product[20]));
    fir_product #(.IN_W(DATA_W+1), .COEFF(-73))  u_prod_21 (.sample(pair_sum[21]), .product(product[21]));
    fir_product #(.IN_W(DATA_W+1), .COEFF(-62))  u_prod_22 (.sample(pair_sum[22]), .product(product[22]));
    fir_product #(.IN_W(DATA_W+1), .COEFF(-46))  u_prod_23 (.sample(pair_sum[23]), .product(product[23]));
    fir_product #(.IN_W(DATA_W+1), .COEFF(-26))  u_prod_24 (.sample(pair_sum[24]), .product(product[24]));
    fir_product #(.IN_W(DATA_W+1), .COEFF(0))    u_prod_25 (.sample(pair_sum[25]), .product(product[25]));
    fir_product #(.IN_W(DATA_W+1), .COEFF(31))   u_prod_26 (.sample(pair_sum[26]), .product(product[26]));
    fir_product #(.IN_W(DATA_W+1), .COEFF(67))   u_prod_27 (.sample(pair_sum[27]), .product(product[27]));
    fir_product #(.IN_W(DATA_W+1), .COEFF(109))  u_prod_28 (.sample(pair_sum[28]), .product(product[28]));
    fir_product #(.IN_W(DATA_W+1), .COEFF(156))  u_prod_29 (.sample(pair_sum[29]), .product(product[29]));
    fir_product #(.IN_W(DATA_W+1), .COEFF(208))  u_prod_30 (.sample(pair_sum[30]), .product(product[30]));
    fir_product #(.IN_W(DATA_W+1), .COEFF(266))  u_prod_31 (.sample(pair_sum[31]), .product(product[31]));
    fir_product #(.IN_W(DATA_W+1), .COEFF(327))  u_prod_32 (.sample(pair_sum[32]), .product(product[32]));
    fir_product #(.IN_W(DATA_W+1), .COEFF(393))  u_prod_33 (.sample(pair_sum[33]), .product(product[33]));
    fir_product #(.IN_W(DATA_W+1), .COEFF(462))  u_prod_34 (.sample(pair_sum[34]), .product(product[34]));
    fir_product #(.IN_W(DATA_W+1), .COEFF(534))  u_prod_35 (.sample(pair_sum[35]), .product(product[35]));
    fir_product #(.IN_W(DATA_W+1), .COEFF(607))  u_prod_36 (.sample(pair_sum[36]), .product(product[36]));
    fir_product #(.IN_W(DATA_W+1), .COEFF(682))  u_prod_37 (.sample(pair_sum[37]), .product(product[37]));
    fir_product #(.IN_W(DATA_W+1), .COEFF(756))  u_prod_38 (.sample(pair_sum[38]), .product(product[38]));
    fir_product #(.IN_W(DATA_W+1), .COEFF(830))  u_prod_39 (.sample(pair_sum[39]), .product(product[39]));
    fir_product #(.IN_W(DATA_W+1), .COEFF(901))  u_prod_40 (.sample(pair_sum[40]), .product(product[40]));
    fir_product #(.IN_W(DATA_W+1), .COEFF(970))  u_prod_41 (.sample(pair_sum[41]), .product(product[41]));
    fir_product #(.IN_W(DATA_W+1), .COEFF(1034)) u_prod_42 (.sample(pair_sum[42]), .product(product[42]));
    fir_product #(.IN_W(DATA_W+1), .COEFF(1094)) u_prod_43 (.sample(pair_sum[43]), .product(product[43]));
    fir_product #(.IN_W(DATA_W+1), .COEFF(1147)) u_prod_44 (.sample(pair_sum[44]), .product(product[44]));
    fir_product #(.IN_W(DATA_W+1), .COEFF(1194)) u_prod_45 (.sample(pair_sum[45]), .product(product[45]));
    fir_product #(.IN_W(DATA_W+1), .COEFF(1233)) u_prod_46 (.sample(pair_sum[46]), .product(product[46]));
    fir_product #(.IN_W(DATA_W+1), .COEFF(1265)) u_prod_47 (.sample(pair_sum[47]), .product(product[47]));
    fir_product #(.IN_W(DATA_W+1), .COEFF(1287)) u_prod_48 (.sample(pair_sum[48]), .product(product[48]));
    fir_product #(.IN_W(DATA_W+1), .COEFF(1301)) u_prod_49 (.sample(pair_sum[49]), .product(product[49]));
    fir_product #(.IN_W(DATA_W),   .COEFF(1306)) u_prod_50 (.sample(sample[50]),   .product(product[50]));

    fir_accumulator #(.ACC_W(ACC_W)) u_acc (
        .p0(product[0]),   .p1(product[1]),   .p2(product[2]),   .p3(product[3]),
        .p4(product[4]),   .p5(product[5]),   .p6(product[6]),   .p7(product[7]),
        .p8(product[8]),   .p9(product[9]),   .p10(product[10]), .p11(product[11]),
        .p12(product[12]), .p13(product[13]), .p14(product[14]), .p15(product[15]),
        .p16(product[16]), .p17(product[17]), .p18(product[18]), .p19(product[19]),
        .p20(product[20]), .p21(product[21]), .p22(product[22]), .p23(product[23]),
        .p24(product[24]), .p25(product[25]), .p26(product[26]), .p27(product[27]),
        .p28(product[28]), .p29(product[29]), .p30(product[30]), .p31(product[31]),
        .p32(product[32]), .p33(product[33]), .p34(product[34]), .p35(product[35]),
        .p36(product[36]), .p37(product[37]), .p38(product[38]), .p39(product[39]),
        .p40(product[40]), .p41(product[41]), .p42(product[42]), .p43(product[43]),
        .p44(product[44]), .p45(product[45]), .p46(product[46]), .p47(product[47]),
        .p48(product[48]), .p49(product[49]), .p50(product[50]), .acc(acc_sum)
    );

    fir_q15_quantizer #(.ACC_W(ACC_W), .OUT_W(OUT_W)) u_quant (
        .acc(acc_sum),
        .data_out(quantized)
    );

    assign valid_out = valid_r;
    assign data_out  = data_out_r;

    always @(posedge clk) begin
        if (rst) begin
            valid_r <= 1'b0;
            data_out_r <= {OUT_W{1'b0}};
            for (i = 0; i < 100; i = i + 1) begin
                delay_line[i] <= {DATA_W{1'b0}};
            end
        end else begin
            valid_r <= valid_in;
            if (valid_in) begin
                data_out_r <= quantized;
                delay_line[0] <= $signed(data_in);
                for (i = 1; i < 100; i = i + 1) begin
                    delay_line[i] <= delay_line[i-1];
                end
            end
        end
    end

endmodule