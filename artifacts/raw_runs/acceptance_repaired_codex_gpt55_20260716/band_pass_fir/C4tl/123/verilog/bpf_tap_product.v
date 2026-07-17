`timescale 1ns/1ps

module bpf_tap_product #(
    parameter DATA_W = 20
) (
    input  signed [DATA_W-1:0] sample,
    input  signed [15:0]       coeff,
    output signed [63:0]       product
);

    assign product = $signed(sample) * $signed(coeff);

endmodule