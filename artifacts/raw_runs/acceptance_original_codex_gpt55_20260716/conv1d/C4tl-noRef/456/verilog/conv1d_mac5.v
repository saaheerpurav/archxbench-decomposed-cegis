`timescale 1ns/1ps

module conv1d_mac5 #(
    parameter DATA_W      = 8,
    parameter KERNEL_SIZE = 5,
    parameter GAIN_W      = 4
) (
    input  [5*(DATA_W+GAIN_W+3)-1:0] product_bus,
    output [DATA_W+GAIN_W+3-1:0]     mac_sum
);

    localparam MAC_W = DATA_W + GAIN_W + 3;

    wire [MAC_W-1:0] p0;
    wire [MAC_W-1:0] p1;
    wire [MAC_W-1:0] p2;
    wire [MAC_W-1:0] p3;
    wire [MAC_W-1:0] p4;

    assign p0 = product_bus[MAC_W*1-1:MAC_W*0];
    assign p1 = product_bus[MAC_W*2-1:MAC_W*1];
    assign p2 = product_bus[MAC_W*3-1:MAC_W*2];
    assign p3 = product_bus[MAC_W*4-1:MAC_W*3];
    assign p4 = product_bus[MAC_W*5-1:MAC_W*4];

    assign mac_sum = p0 + p1 + p2 + p3 + p4;

endmodule