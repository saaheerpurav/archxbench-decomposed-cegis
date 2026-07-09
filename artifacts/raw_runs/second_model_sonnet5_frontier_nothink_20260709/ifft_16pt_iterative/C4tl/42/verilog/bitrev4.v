`timescale 1ns/1ps
// Combinational 4-bit index bit-reversal (for N=16)
// Maps idx_in[3:0] -> idx_out[3:0] such that idx_out[i] = idx_in[3-i]
module bitrev4 (
    input  [3:0] idx_in,
    output [3:0] idx_out
);
    assign idx_out[3] = idx_in[0];
    assign idx_out[2] = idx_in[1];
    assign idx_out[1] = idx_in[2];
    assign idx_out[0] = idx_in[3];
endmodule