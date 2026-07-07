`timescale 1ns/1ps

module bpf_accumulator #(
    parameter TAP_CNT = 101,
    parameter PROD_W  = 36,
    parameter ACC_W   = 64
) (
    input  signed [TAP_CNT*PROD_W-1:0] products,
    output reg signed [ACC_W-1:0]      acc_sum
);

    integer i;

    always @* begin
        acc_sum = {ACC_W{1'b0}};
        for (i = 0; i < TAP_CNT; i = i + 1) begin
            acc_sum = acc_sum + {{(ACC_W-PROD_W){products[i*PROD_W + PROD_W - 1]}},
                                 products[i*PROD_W +: PROD_W]};
        end
    end

endmodule