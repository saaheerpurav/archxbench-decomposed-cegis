`timescale 1ns/1ps

module fir_symmetric_preadd #(
    parameter DATA_W  = 20,
    parameter TAP_CNT = 101
) (
    input  [TAP_CNT*DATA_W-1:0]                         tap_bus,
    output [((TAP_CNT-1)/2)*(DATA_W+1)-1:0]             pair_sum_bus,
    output [DATA_W-1:0]                                 center_sample
);
    localparam PAIR_CNT = (TAP_CNT - 1) / 2;
    localparam SUM_W    = DATA_W + 1;

    genvar i;
    generate
        for (i = 0; i < PAIR_CNT; i = i + 1) begin : GEN_PAIR_SUM
            wire signed [DATA_W-1:0] left_sample;
            wire signed [DATA_W-1:0] right_sample;
            wire signed [SUM_W-1:0]  pair_sum;

            assign left_sample  = tap_bus[i*DATA_W +: DATA_W];
            assign right_sample = tap_bus[(TAP_CNT-1-i)*DATA_W +: DATA_W];
            assign pair_sum     = {left_sample[DATA_W-1], left_sample} +
                                  {right_sample[DATA_W-1], right_sample};

            assign pair_sum_bus[i*SUM_W +: SUM_W] = pair_sum;
        end
    endgenerate

    assign center_sample = tap_bus[PAIR_CNT*DATA_W +: DATA_W];
endmodule