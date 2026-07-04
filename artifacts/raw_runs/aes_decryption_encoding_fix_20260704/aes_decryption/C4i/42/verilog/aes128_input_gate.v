`timescale 1ns/1ps

module aes128_input_gate (
    input  wire start,
    input  wire valid_in,
    input  wire mode,
    output wire accept
);

    assign accept = start & valid_in & mode;

endmodule