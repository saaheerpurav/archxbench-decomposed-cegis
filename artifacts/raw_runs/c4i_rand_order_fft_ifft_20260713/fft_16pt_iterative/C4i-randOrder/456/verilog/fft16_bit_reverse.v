`timescale 1ns/1ps

module fft16_bit_reverse #(
    parameter LOGN = 4
) (
    input  [LOGN-1:0] idx,
    output [LOGN-1:0] rev_idx
);

    genvar i;

    generate
        for (i = 0; i < LOGN; i = i + 1) begin : g_bit_reverse
            assign rev_idx[i] = idx[LOGN-1-i];
        end
    endgenerate

endmodule