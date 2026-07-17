`timescale 1ns/1ps

module fir_tap_mult #(
    parameter DATA_W  = 20,
    parameter COEFF_W = 16,
    parameter PROD_W  = 36
) (
    input  signed [DATA_W-1:0]  sample,
    input  signed [COEFF_W-1:0] coeff,
    output signed [PROD_W-1:0]  product
);

    assign product = sample * coeff;

endmodule