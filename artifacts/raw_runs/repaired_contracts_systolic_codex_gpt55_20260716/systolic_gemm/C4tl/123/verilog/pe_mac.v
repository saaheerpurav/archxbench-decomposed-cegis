`timescale 1ns/1ps

module pe_mac(north_in, west_in, accum_in, accum_out);
    input [31:0] north_in;
    input [31:0] west_in;
    input [63:0] accum_in;
    output [63:0] accum_out;

    wire signed [31:0] north_signed;
    wire signed [31:0] west_signed;
    wire signed [63:0] product_signed;

    assign north_signed = north_in;
    assign west_signed = west_in;
    assign product_signed = north_signed * west_signed;

    assign accum_out = accum_in + product_signed;
endmodule