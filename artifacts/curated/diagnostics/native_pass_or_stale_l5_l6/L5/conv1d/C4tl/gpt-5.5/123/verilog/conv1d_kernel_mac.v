`timescale 1ns/1ps

module conv1d_kernel_mac #(
    parameter DATA_W = 8,
    parameter GAIN_W = 4
) (
    input  [DATA_W-1:0]             tap0,
    input  [DATA_W-1:0]             tap1,
    input  [DATA_W-1:0]             tap2,
    input  [DATA_W-1:0]             tap3,
    input  [DATA_W-1:0]             tap4,
    output [DATA_W+GAIN_W+3-1:0]    mac_sum
);

    localparam ACC_W = DATA_W + GAIN_W + 3;

    wire [ACC_W-1:0] product0;
    wire [ACC_W-1:0] product1;
    wire [ACC_W-1:0] product2;
    wire [ACC_W-1:0] product3;
    wire [ACC_W-1:0] product4;

    assign product0 = {{(ACC_W-DATA_W){1'b0}}, tap0} * 2;
    assign product1 = {{(ACC_W-DATA_W){1'b0}}, tap1} * 8;
    assign product2 = {{(ACC_W-DATA_W){1'b0}}, tap2} * 12;
    assign product3 = {{(ACC_W-DATA_W){1'b0}}, tap3} * 8;
    assign product4 = {{(ACC_W-DATA_W){1'b0}}, tap4} * 2;

    assign mac_sum = product0 + product1 + product2 + product3 + product4;

endmodule