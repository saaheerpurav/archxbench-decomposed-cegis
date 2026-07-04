`timescale 1ns/1ps

module fft64_bit_reverse #(
    parameter ADDR_W = 6
) (
    input [ADDR_W-1:0] addr,
    output [ADDR_W-1:0] rev_addr
);
    genvar i;
    generate
        for (i = 0; i < ADDR_W; i = i + 1) begin : gen_reverse
            assign rev_addr[i] = addr[ADDR_W-1-i];
        end
    endgenerate
endmodule