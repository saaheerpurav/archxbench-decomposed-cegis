`timescale 1ns/1ps

module aes_subbytes (
    input  wire [127:0] state_in,
    output wire [127:0] state_out
);

    aes_sbox sbox_0  (.in(state_in[  7:  0]), .out(state_out[  7:  0]));
    aes_sbox sbox_1  (.in(state_in[ 15:  8]), .out(state_out[ 15:  8]));
    aes_sbox sbox_2  (.in(state_in[ 23: 16]), .out(state_out[ 23: 16]));
    aes_sbox sbox_3  (.in(state_in[ 31: 24]), .out(state_out[ 31: 24]));

    aes_sbox sbox_4  (.in(state_in[ 39: 32]), .out(state_out[ 39: 32]));
    aes_sbox sbox_5  (.in(state_in[ 47: 40]), .out(state_out[ 47: 40]));
    aes_sbox sbox_6  (.in(state_in[ 55: 48]), .out(state_out[ 55: 48]));
    aes_sbox sbox_7  (.in(state_in[ 63: 56]), .out(state_out[ 63: 56]));

    aes_sbox sbox_8  (.in(state_in[ 71: 64]), .out(state_out[ 71: 64]));
    aes_sbox sbox_9  (.in(state_in[ 79: 72]), .out(state_out[ 79: 72]));
    aes_sbox sbox_10 (.in(state_in[ 87: 80]), .out(state_out[ 87: 80]));
    aes_sbox sbox_11 (.in(state_in[ 95: 88]), .out(state_out[ 95: 88]));

    aes_sbox sbox_12 (.in(state_in[103: 96]), .out(state_out[103: 96]));
    aes_sbox sbox_13 (.in(state_in[111:104]), .out(state_out[111:104]));
    aes_sbox sbox_14 (.in(state_in[119:112]), .out(state_out[119:112]));
    aes_sbox sbox_15 (.in(state_in[127:120]), .out(state_out[127:120]));

endmodule