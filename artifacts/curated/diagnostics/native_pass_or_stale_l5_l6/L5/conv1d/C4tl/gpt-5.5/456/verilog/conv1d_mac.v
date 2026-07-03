`timescale 1ns/1ps

module conv1d_mac #(
    parameter KERNEL_SIZE = 5,
    parameter MAC_W       = 15
) (
    input  [MAC_W*KERNEL_SIZE-1:0] products_flat,
    output [MAC_W-1:0]             mac_sum
);

    wire [MAC_W-1:0] p0;
    wire [MAC_W-1:0] p1;
    wire [MAC_W-1:0] p2;
    wire [MAC_W-1:0] p3;
    wire [MAC_W-1:0] p4;

    assign p0 = products_flat[MAC_W*1-1:MAC_W*0];
    assign p1 = products_flat[MAC_W*2-1:MAC_W*1];
    assign p2 = products_flat[MAC_W*3-1:MAC_W*2];
    assign p3 = products_flat[MAC_W*4-1:MAC_W*3];
    assign p4 = products_flat[MAC_W*5-1:MAC_W*4];

    assign mac_sum = p0 + p1 + p2 + p3 + p4;

endmodule