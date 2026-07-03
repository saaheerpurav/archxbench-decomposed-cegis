`timescale 1ns/1ps

module signed_mult32(a, b, product);
    input [31:0] a;
    input [31:0] b;
    output [63:0] product;

    wire signed [63:0] a_signed;
    wire signed [63:0] b_signed;

    assign a_signed = {{32{a[31]}}, a};
    assign b_signed = {{32{b[31]}}, b};

    assign product = a_signed * b_signed;
endmodule