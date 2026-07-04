`timescale 1ns/1ps

module ifft16_bit_reverse (
    input  [3:0] idx,
    output [3:0] rev_idx
);
    assign rev_idx = {idx[0], idx[1], idx[2], idx[3]};
endmodule