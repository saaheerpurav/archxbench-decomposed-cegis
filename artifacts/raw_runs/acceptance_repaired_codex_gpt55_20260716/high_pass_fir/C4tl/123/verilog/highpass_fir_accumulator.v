`timescale 1ns/1ps

module highpass_fir_accumulator #(
    parameter TAP_CNT = 101,
    parameter PROD_W  = 36,
    parameter ACC_W   = 64
) (
    input  [TAP_CNT*PROD_W-1:0] products_flat,
    output reg signed [ACC_W-1:0] acc_sum
);
    integer i;
    reg signed [PROD_W-1:0] product_i;

    always @* begin
        acc_sum = {ACC_W{1'b0}};
        for (i = 0; i < TAP_CNT; i = i + 1) begin
            product_i = products_flat[i*PROD_W +: PROD_W];
            acc_sum = acc_sum + product_i;
        end
    end
endmodule