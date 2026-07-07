`timescale 1ns/1ps

module fir_symmetric_sum_pack #(
    parameter DATA_W  = 20,
    parameter TAP_CNT = 101
) (
    input  [DATA_W*TAP_CNT-1:0] sample_flat,
    output [(DATA_W+1)*((TAP_CNT-1)/2)-1:0] pair_sum_flat,
    output signed [DATA_W-1:0] center_sample
);
    localparam PAIR_CNT = (TAP_CNT - 1) / 2;
    localparam PREADD_W = DATA_W + 1;

    genvar i;
    generate
        for (i = 0; i < PAIR_CNT; i = i + 1) begin : gen_pair_sum
            wire signed [DATA_W-1:0] lhs_sample;
            wire signed [DATA_W-1:0] rhs_sample;
            wire signed [PREADD_W-1:0] lhs_ext;
            wire signed [PREADD_W-1:0] rhs_ext;
            wire signed [PREADD_W-1:0] pair_sum;

            assign lhs_sample = sample_flat[i*DATA_W +: DATA_W];
            assign rhs_sample = sample_flat[(TAP_CNT-1-i)*DATA_W +: DATA_W];

            assign lhs_ext = {lhs_sample[DATA_W-1], lhs_sample};
            assign rhs_ext = {rhs_sample[DATA_W-1], rhs_sample};
            assign pair_sum = lhs_ext + rhs_ext;

            assign pair_sum_flat[i*PREADD_W +: PREADD_W] = pair_sum;
        end
    endgenerate

    assign center_sample = sample_flat[PAIR_CNT*DATA_W +: DATA_W];

endmodule