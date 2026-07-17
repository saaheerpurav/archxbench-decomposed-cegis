`timescale 1ns/1ps

module pe_cell(north_in, west_in, acc_in, south_out, east_out, acc_out);
    input  [31:0] north_in;
    input  [31:0] west_in;
    input  [63:0] acc_in;
    output [31:0] south_out;
    output [31:0] east_out;
    output [63:0] acc_out;

    wire signed [31:0] north_signed;
    wire signed [31:0] west_signed;
    wire signed [63:0] acc_signed;
    wire signed [63:0] product_signed;

    assign north_signed = north_in;
    assign west_signed = west_in;
    assign acc_signed = acc_in;

    assign product_signed = north_signed * west_signed;

    assign south_out = north_in;
    assign east_out = west_in;
    assign acc_out = acc_signed + product_signed;
endmodule