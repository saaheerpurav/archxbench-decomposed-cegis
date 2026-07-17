`timescale 1ns/1ps

module aes128_inv_shiftrows (
    input  [127:0] state_in,
    output [127:0] state_out
);

    function [7:0] byte_at;
        input [127:0] state;
        input integer index;
        begin
            byte_at = state[127 - (8 * index) -: 8];
        end
    endfunction

    assign state_out = {
        byte_at(state_in,  0), byte_at(state_in, 13),
        byte_at(state_in, 10), byte_at(state_in,  7),

        byte_at(state_in,  4), byte_at(state_in,  1),
        byte_at(state_in, 14), byte_at(state_in, 11),

        byte_at(state_in,  8), byte_at(state_in,  5),
        byte_at(state_in,  2), byte_at(state_in, 15),

        byte_at(state_in, 12), byte_at(state_in,  9),
        byte_at(state_in,  6), byte_at(state_in,  3)
    };

endmodule