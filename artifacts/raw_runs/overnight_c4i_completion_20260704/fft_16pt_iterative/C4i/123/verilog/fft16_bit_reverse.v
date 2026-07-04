`timescale 1ns/1ps

module fft16_bit_reverse #(
    parameter LOGN = 4
) (
    input  wire [LOGN-1:0] index_in,
    output wire [LOGN-1:0] index_out
);

    genvar i;

    generate
        for (i = 0; i < LOGN; i = i + 1) begin : REV
            assign index_out[i] = index_in[LOGN-1-i];
        end
    endgenerate

endmodule