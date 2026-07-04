`timescale 1ns/1ps

module fft16_bit_reverse (
    input  [3:0] in_idx,
    output [3:0] out_idx
);

    assign out_idx = {in_idx[0], in_idx[1], in_idx[2], in_idx[3]};

endmodule