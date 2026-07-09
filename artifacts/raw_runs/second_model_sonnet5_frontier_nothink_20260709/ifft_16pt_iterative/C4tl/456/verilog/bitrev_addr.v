module bitrev_addr #(
    parameter W = 4
) (
    input  [W-1:0] addr_in,
    output [W-1:0] addr_out
);
    genvar i;
    generate
        for (i = 0; i < W; i = i + 1) begin : REV
            assign addr_out[i] = addr_in[W-1-i];
        end
    endgenerate
endmodule