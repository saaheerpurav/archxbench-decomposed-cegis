`timescale 1ns/1ps

// Combinational bit-reversal address generator
// For a WIDTH-bit input address, reverses the bit order to produce
// the bit-reversed address used to permute samples before FFT/IFFT
// butterfly stages (standard DIT bit-reversal permutation).
module bitrev_addr #(
    parameter WIDTH = 4
) (
    input  [WIDTH-1:0] addr_in,
    output [WIDTH-1:0] addr_out
);

    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : REV
            assign addr_out[i] = addr_in[WIDTH-1-i];
        end
    endgenerate

endmodule