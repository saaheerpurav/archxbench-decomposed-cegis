module bitrev_addr #(
    parameter LOGN = 4
) (
    input  [LOGN-1:0] idx,
    output [LOGN-1:0] rev
);
    // Reverse the lower LOGN bits of idx (bit-reversal addressing for FFT input reorder)
    genvar i;
    generate
        for (i = 0; i < LOGN; i = i + 1) begin : bitrev_gen
            assign rev[i] = idx[LOGN-1-i];
        end
    endgenerate
endmodule