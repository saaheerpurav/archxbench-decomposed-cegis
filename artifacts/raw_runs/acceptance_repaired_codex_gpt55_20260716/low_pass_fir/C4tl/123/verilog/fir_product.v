`timescale 1ns/1ps

module fir_product #(
    parameter IN_W  = 21,
    parameter COEFF = 0
) (
    input  signed [IN_W-1:0] sample,
    output signed [31:0]     product
);
    assign product = $signed(sample) * $signed(COEFF);
endmodule