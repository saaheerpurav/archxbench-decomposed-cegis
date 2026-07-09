module bitrev_addr #(
    parameter LOGN = 4
) (
    input  [3:0] addr_in,
    output [3:0] addr_out
);
    // Reverse the lower LOGN bits of addr_in; any unused upper bits
    // (when LOGN < 4) are forced to zero in the output.
    genvar i;
    generate
        for (i = 0; i < 4; i = i + 1) begin : REV
            if (i < LOGN) begin : ACTIVE
                assign addr_out[i] = addr_in[LOGN-1-i];
            end else begin : INACTIVE
                assign addr_out[i] = 1'b0;
            end
        end
    endgenerate
endmodule