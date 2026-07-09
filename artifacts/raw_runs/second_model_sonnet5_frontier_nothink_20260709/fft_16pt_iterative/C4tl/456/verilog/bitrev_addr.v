module bitrev_addr #(
    parameter LOGN = 4
) (
    input  [LOGN-1:0] idx_in,
    output [LOGN-1:0] idx_out
);
    genvar i;
    generate
        for (i = 0; i < LOGN; i = i + 1) begin: REV
            assign idx_out[i] = idx_in[LOGN-1-i];
        end
    endgenerate
endmodule