`timescale 1ns/1ps

module fir_symmetric_preadd #(
    parameter DATA_W  = 20,
    parameter TAP_CNT = 101
) (
    input  [DATA_W*TAP_CNT-1:0]             taps_flat,
    output [(DATA_W+1)*((TAP_CNT-1)/2)-1:0] pair_sums_flat,
    output [DATA_W-1:0]                     center_sample
);
    localparam PAIR_CNT = (TAP_CNT - 1) / 2;
    localparam PREADD_W = DATA_W + 1;

    generate
        genvar i;
        for (i = 0; i < PAIR_CNT; i = i + 1) begin : PREADD
            wire signed [DATA_W-1:0] left_sample;
            wire signed [DATA_W-1:0] right_sample;
            wire signed [PREADD_W-1:0] pair_sum;

            assign left_sample  = taps_flat[i*DATA_W +: DATA_W];
            assign right_sample = taps_flat[(TAP_CNT-1-i)*DATA_W +: DATA_W];
            assign pair_sum = {left_sample[DATA_W-1], left_sample} +
                              {right_sample[DATA_W-1], right_sample};
            assign pair_sums_flat[i*PREADD_W +: PREADD_W] = pair_sum;
        end
    endgenerate

    assign center_sample = taps_flat[PAIR_CNT*DATA_W +: DATA_W];
endmodule