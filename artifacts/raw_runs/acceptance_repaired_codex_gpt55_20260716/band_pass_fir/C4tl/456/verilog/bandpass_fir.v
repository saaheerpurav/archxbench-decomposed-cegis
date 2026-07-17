`timescale 1ns/1ps

module bandpass_fir #(
    parameter DATA_W  = 20,
    parameter TAP_CNT = 101,
    parameter GAIN_W  = 4
) (
    input                          clk,
    input                          rst,
    input                          valid_in,
    input      [DATA_W-1:0]        data_in,
    output reg                     valid_out,
    output reg [DATA_W+GAIN_W-1:0] data_out
);

    localparam OUT_W   = DATA_W + GAIN_W;
    localparam COEFF_W = 16;
    localparam PROD_W  = DATA_W + COEFF_W;
    localparam ACC_W   = 64;

    reg signed [DATA_W-1:0] delay_line [0:TAP_CNT-1];

    wire signed [DATA_W-1:0] input_sample;
    wire signed [DATA_W-1:0] tap_sample [0:TAP_CNT-1];
    wire signed [COEFF_W-1:0] coeff [0:TAP_CNT-1];
    wire signed [PROD_W-1:0] product [0:TAP_CNT-1];
    wire signed [ACC_W-1:0] acc_sum;
    wire signed [OUT_W-1:0] normalized_out;

    integer i;
    genvar g;

    fir_input_cast #(
        .DATA_W(DATA_W)
    ) u_input_cast (
        .data_in(data_in),
        .sample_out(input_sample)
    );

    generate
        for (g = 0; g < TAP_CNT; g = g + 1) begin : gen_taps
            assign tap_sample[g] = (g == 0) ? input_sample : delay_line[g-1];

            fir_coeff_rom #(
                .COEFF_W(COEFF_W)
            ) u_coeff_rom (
                .tap_index(g[7:0]),
                .coeff(coeff[g])
            );

            fir_tap_multiply #(
                .DATA_W(DATA_W),
                .COEFF_W(COEFF_W),
                .PROD_W(PROD_W)
            ) u_tap_multiply (
                .sample(tap_sample[g]),
                .coeff(coeff[g]),
                .product(product[g])
            );
        end
    endgenerate

    fir_accumulator_101 #(
        .PROD_W(PROD_W),
        .ACC_W(ACC_W)
    ) u_accumulator (
        .p000(product[0]),   .p001(product[1]),   .p002(product[2]),   .p003(product[3]),
        .p004(product[4]),   .p005(product[5]),   .p006(product[6]),   .p007(product[7]),
        .p008(product[8]),   .p009(product[9]),   .p010(product[10]),  .p011(product[11]),
        .p012(product[12]),  .p013(product[13]),  .p014(product[14]),  .p015(product[15]),
        .p016(product[16]),  .p017(product[17]),  .p018(product[18]),  .p019(product[19]),
        .p020(product[20]),  .p021(product[21]),  .p022(product[22]),  .p023(product[23]),
        .p024(product[24]),  .p025(product[25]),  .p026(product[26]),  .p027(product[27]),
        .p028(product[28]),  .p029(product[29]),  .p030(product[30]),  .p031(product[31]),
        .p032(product[32]),  .p033(product[33]),  .p034(product[34]),  .p035(product[35]),
        .p036(product[36]),  .p037(product[37]),  .p038(product[38]),  .p039(product[39]),
        .p040(product[40]),  .p041(product[41]),  .p042(product[42]),  .p043(product[43]),
        .p044(product[44]),  .p045(product[45]),  .p046(product[46]),  .p047(product[47]),
        .p048(product[48]),  .p049(product[49]),  .p050(product[50]),  .p051(product[51]),
        .p052(product[52]),  .p053(product[53]),  .p054(product[54]),  .p055(product[55]),
        .p056(product[56]),  .p057(product[57]),  .p058(product[58]),  .p059(product[59]),
        .p060(product[60]),  .p061(product[61]),  .p062(product[62]),  .p063(product[63]),
        .p064(product[64]),  .p065(product[65]),  .p066(product[66]),  .p067(product[67]),
        .p068(product[68]),  .p069(product[69]),  .p070(product[70]),  .p071(product[71]),
        .p072(product[72]),  .p073(product[73]),  .p074(product[74]),  .p075(product[75]),
        .p076(product[76]),  .p077(product[77]),  .p078(product[78]),  .p079(product[79]),
        .p080(product[80]),  .p081(product[81]),  .p082(product[82]),  .p083(product[83]),
        .p084(product[84]),  .p085(product[85]),  .p086(product[86]),  .p087(product[87]),
        .p088(product[88]),  .p089(product[89]),  .p090(product[90]),  .p091(product[91]),
        .p092(product[92]),  .p093(product[93]),  .p094(product[94]),  .p095(product[95]),
        .p096(product[96]),  .p097(product[97]),  .p098(product[98]),  .p099(product[99]),
        .p100(product[100]),
        .sum(acc_sum)
    );

    fir_q15_normalize #(
        .ACC_W(ACC_W),
        .OUT_W(OUT_W)
    ) u_q15_normalize (
        .acc(acc_sum),
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
                delay_line[0] <= input_sample;
                for (i = 1; i < TAP_CNT; i = i + 1)
                    delay_line[i] <= delay_line[i-1];
            end
        end
    end

endmodule