`timescale 1ns/1ps

module conv1d_weighted_products #(
    parameter DATA_W      = 8,
    parameter KERNEL_SIZE = 5,
    parameter GAIN_W      = 4
) (
    input  [KERNEL_SIZE*DATA_W-1:0] tap_bus,
    output [5*(DATA_W+GAIN_W+3)-1:0] product_bus
);

    localparam MAC_W = DATA_W + GAIN_W + 3;

    wire [DATA_W-1:0] x0;
    wire [DATA_W-1:0] x1;
    wire [DATA_W-1:0] x2;
    wire [DATA_W-1:0] x3;
    wire [DATA_W-1:0] x4;

    wire [MAC_W-1:0] p0;
    wire [MAC_W-1:0] p1;
    wire [MAC_W-1:0] p2;
    wire [MAC_W-1:0] p3;
    wire [MAC_W-1:0] p4;

    assign x0 = tap_bus[DATA_W*1-1:DATA_W*0];
    assign x1 = tap_bus[DATA_W*2-1:DATA_W*1];
    assign x2 = tap_bus[DATA_W*3-1:DATA_W*2];
    assign x3 = tap_bus[DATA_W*4-1:DATA_W*3];
    assign x4 = tap_bus[DATA_W*5-1:DATA_W*4];

    assign p0 = {{(MAC_W-DATA_W){1'b0}}, x0} << 1;
    assign p1 = {{(MAC_W-DATA_W){1'b0}}, x1} << 3;
    assign p2 = ({{(MAC_W-DATA_W){1'b0}}, x2} << 3) + ({{(MAC_W-DATA_W){1'b0}}, x2} << 2);
    assign p3 = {{(MAC_W-DATA_W){1'b0}}, x3} << 3;
    assign p4 = {{(MAC_W-DATA_W){1'b0}}, x4} << 1;

    assign product_bus[MAC_W*1-1:MAC_W*0] = p0;
    assign product_bus[MAC_W*2-1:MAC_W*1] = p1;
    assign product_bus[MAC_W*3-1:MAC_W*2] = p2;
    assign product_bus[MAC_W*4-1:MAC_W*3] = p3;
    assign product_bus[MAC_W*5-1:MAC_W*4] = p4;

endmodule