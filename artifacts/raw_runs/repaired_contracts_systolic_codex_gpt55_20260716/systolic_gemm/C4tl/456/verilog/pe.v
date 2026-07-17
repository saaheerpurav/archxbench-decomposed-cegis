`timescale 1ns/1ps

module pe(north_in, west_in, clk, rst, south_out, east_out, result);
    input [31:0] north_in, west_in;
    input clk, rst;
    output reg [31:0] south_out, east_out;
    output reg [63:0] result;

    wire signed [31:0] north_signed;
    wire signed [31:0] west_signed;
    wire signed [63:0] product_signed;

    assign north_signed = north_in;
    assign west_signed = west_in;
    assign product_signed = north_signed * west_signed;

    always @(*) begin
        south_out = north_in;
        east_out = west_in;
        result = product_signed;
    end
endmodule