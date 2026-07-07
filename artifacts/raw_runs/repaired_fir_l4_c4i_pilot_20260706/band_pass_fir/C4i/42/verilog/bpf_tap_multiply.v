`timescale 1ns/1ps

module bpf_tap_multiply #(
    parameter DATA_W  = 20,
    parameter COEFF_W = 16
) (
    input  signed [DATA_W-1:0]          sample,
    input  signed [COEFF_W-1:0]         coeff,
    output signed [DATA_W+COEFF_W-1:0]  product
);

    assign product = sample * coeff;

endmodule