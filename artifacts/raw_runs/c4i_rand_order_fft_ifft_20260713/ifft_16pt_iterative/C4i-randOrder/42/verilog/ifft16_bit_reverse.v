`timescale 1ns/1ps

module ifft16_bit_reverse (
    input  [3:0] idx_in,
    output [3:0] idx_out
);
    assign idx_out = {idx_in[0], idx_in[1], idx_in[2], idx_in[3]};
endmodule