`timescale 1ns/1ps

module bpf_accumulator #(
    parameter TAP_CNT = 101,
    parameter PROD_W  = 36,
    parameter ACC_W   = 64
) (
    input  [TAP_CNT*PROD_W-1:0] products_flat,
    output reg signed [ACC_W-1:0] acc
);
    integer i;
    reg signed [PROD_W-1:0] term;
    reg signed [ACC_W-1:0]  term_ext;

    always @* begin
        acc = {ACC_W{1'b0}};

        for (i = 0; i < TAP_CNT; i = i + 1) begin
            term = products_flat[i*PROD_W +: PROD_W];
            term_ext = term;
            acc = acc + term_ext;
        end
    end
endmodule