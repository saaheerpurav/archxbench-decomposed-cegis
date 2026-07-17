`timescale 1ns/1ps

module pe_forward(north_in, west_in, south_out, east_out);
    input [31:0] north_in;
    input [31:0] west_in;
    output [31:0] south_out;
    output [31:0] east_out;

    assign south_out = north_in;
    assign east_out = west_in;
endmodule