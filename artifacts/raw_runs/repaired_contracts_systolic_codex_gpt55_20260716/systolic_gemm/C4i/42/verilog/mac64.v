`timescale 1ns/1ps

module mac64(a, b, acc_in, acc_out);
    input [31:0] a;
    input [31:0] b;
    input [63:0] acc_in;
    output [63:0] acc_out;

    wire signed [31:0] a_signed;
    wire signed [31:0] b_signed;
    wire signed [63:0] product_signed;
    wire signed [63:0] acc_signed;

    assign a_signed = a;
    assign b_signed = b;
    assign acc_signed = acc_in;
    assign product_signed = a_signed * b_signed;
    assign acc_out = acc_signed + product_signed;
endmodule