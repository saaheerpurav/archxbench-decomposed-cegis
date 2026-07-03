`timescale 1ns/1ps

module pe_cell(west_in, north_in, acc_in, east_out, south_out, acc_out);
    input [31:0] west_in;
    input [31:0] north_in;
    input [63:0] acc_in;
    output [31:0] east_out;
    output [31:0] south_out;
    output [63:0] acc_out;

    assign east_out = west_in;
    assign south_out = north_in;
    assign acc_out = $signed(acc_in) + ($signed(west_in) * $signed(north_in));
endmodule