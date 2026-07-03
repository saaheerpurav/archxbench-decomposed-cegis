`timescale 1ns/1ps

module accumulate64(acc_in, product, acc_out);
    input [63:0] acc_in;
    input [63:0] product;
    output [63:0] acc_out;

    assign acc_out = $signed(acc_in) + $signed(product);
endmodule