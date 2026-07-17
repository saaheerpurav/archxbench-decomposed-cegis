`timescale 1ns/1ps

module fir_parallel_mac #(
    parameter DATA_W  = 20,
    parameter TAP_CNT = 101,
    parameter COEFF_W = 16,
    parameter ACC_W   = 64
) (
    input  [(DATA_W+1)*((TAP_CNT-1)/2)-1:0] pair_sums_flat,
    input  [DATA_W-1:0]                     center_sample,
    input  [COEFF_W*((TAP_CNT+1)/2)-1:0]    coeffs_flat,
    output [ACC_W-1:0]                      acc_out
);
    localparam PAIR_CNT  = (TAP_CNT - 1) / 2;
    localparam UNIQUE_CNT = (TAP_CNT + 1) / 2;
    localparam PREADD_W  = DATA_W + 1;

    integer i;
    reg signed [ACC_W-1:0] acc;
    reg signed [PREADD_W-1:0] pair_sum;
    reg signed [DATA_W-1:0] center_s;
    reg signed [COEFF_W-1:0] coeff;

    always @* begin
        acc = {ACC_W{1'b0}};
        for (i = 0; i < PAIR_CNT; i = i + 1) begin
            pair_sum = pair_sums_flat[i*PREADD_W +: PREADD_W];
            coeff    = coeffs_flat[i*COEFF_W +: COEFF_W];
            acc      = acc + (pair_sum * coeff);
        end

        center_s = center_sample;
        coeff    = coeffs_flat[(UNIQUE_CNT-1)*COEFF_W +: COEFF_W];
        acc      = acc + (center_s * coeff);
    end

    assign acc_out = acc;
endmodule