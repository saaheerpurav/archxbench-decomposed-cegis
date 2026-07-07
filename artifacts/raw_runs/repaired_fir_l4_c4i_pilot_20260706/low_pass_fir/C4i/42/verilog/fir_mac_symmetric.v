`timescale 1ns/1ps

module fir_mac_symmetric #(
    parameter DATA_W  = 20,
    parameter TAP_CNT = 101,
    parameter COEFF_W = 16,
    parameter ACC_W   = 64
) (
    input  [COEFF_W*TAP_CNT-1:0] coeff_flat,
    input  [(DATA_W+1)*((TAP_CNT-1)/2)-1:0] pair_sum_flat,
    input  signed [DATA_W-1:0] center_sample,
    output reg signed [ACC_W-1:0] acc_out
);
    localparam PAIR_CNT = (TAP_CNT - 1) / 2;
    localparam PREADD_W = DATA_W + 1;

    integer i;

    reg signed [PREADD_W-1:0] pair_sum;
    reg signed [COEFF_W-1:0]  coeff;
    reg signed [COEFF_W-1:0]  center_coeff;
    reg signed [ACC_W-1:0]    product_ext;

    always @* begin
        acc_out = {ACC_W{1'b0}};

        for (i = 0; i < PAIR_CNT; i = i + 1) begin
            pair_sum = $signed(pair_sum_flat[i*PREADD_W +: PREADD_W]);
            coeff    = $signed(coeff_flat[i*COEFF_W +: COEFF_W]);

            product_ext = $signed(pair_sum) * $signed(coeff);
            acc_out = acc_out + product_ext;
        end

        center_coeff = $signed(coeff_flat[PAIR_CNT*COEFF_W +: COEFF_W]);

        product_ext = $signed(center_sample) * $signed(center_coeff);
        acc_out = acc_out + product_ext;
    end
endmodule