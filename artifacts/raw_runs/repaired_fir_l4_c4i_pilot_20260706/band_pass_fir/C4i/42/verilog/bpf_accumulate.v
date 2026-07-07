`timescale 1ns/1ps

module bpf_accumulate #(
    parameter TAP_CNT = 101,
    parameter PROD_W  = 36,
    parameter ACC_W   = 64
) (
    input  [TAP_CNT*PROD_W-1:0] products,
    output reg signed [ACC_W-1:0] acc_sum
);

    integer i;
    reg signed [PROD_W-1:0] prod_i;
    reg signed [ACC_W-1:0] sum_next;

    always @* begin
        sum_next = {ACC_W{1'b0}};

        for (i = 0; i < TAP_CNT; i = i + 1) begin
            prod_i = products[i*PROD_W +: PROD_W];
            sum_next = sum_next + {{(ACC_W-PROD_W){prod_i[PROD_W-1]}}, prod_i};
        end

        acc_sum = sum_next;
    end

endmodule