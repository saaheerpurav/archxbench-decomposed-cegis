`timescale 1ns/1ps

module aes128_initial_add #(
    parameter RCON = 8'h00
) (
    input  [127:0] data_in,
    input  [127:0] key_in,
    output [127:0] state_out,
    output [127:0] key_out
);

    assign state_out = data_in ^ key_in;
    assign key_out   = key_in;

endmodule