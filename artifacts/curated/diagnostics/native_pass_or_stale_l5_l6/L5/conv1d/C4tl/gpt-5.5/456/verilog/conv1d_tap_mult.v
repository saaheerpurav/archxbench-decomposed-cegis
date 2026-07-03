`timescale 1ns/1ps

module conv1d_tap_mult #(
    parameter DATA_W      = 8,
    parameter KERNEL_SIZE = 5,
    parameter GAIN_W      = 4,
    parameter MAC_W       = DATA_W + GAIN_W + 3
) (
    input  [DATA_W*KERNEL_SIZE-1:0] window_flat,
    output [MAC_W*KERNEL_SIZE-1:0]  products_flat
);

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

    assign x0 = window_flat[DATA_W*1-1:DATA_W*0];
    assign x1 = window_flat[DATA_W*2-1:DATA_W*1];
    assign x2 = window_flat[DATA_W*3-1:DATA_W*2];
    assign x3 = window_flat[DATA_W*4-1:DATA_W*3];
    assign x4 = window_flat[DATA_W*5-1:DATA_W*4];

    assign p0 = {{(MAC_W-DATA_W){1'b0}}, x0} * 4'd2;
    assign p1 = {{(MAC_W-DATA_W){1'b0}}, x1} * 4'd8;
    assign p2 = {{(MAC_W-DATA_W){1'b0}}, x2} * 4'd12;
    assign p3 = {{(MAC_W-DATA_W){1'b0}}, x3} * 4'd8;
    assign p4 = {{(MAC_W-DATA_W){1'b0}}, x4} * 4'd2;

    assign products_flat[MAC_W*1-1:MAC_W*0] = p0;
    assign products_flat[MAC_W*2-1:MAC_W*1] = p1;
    assign products_flat[MAC_W*3-1:MAC_W*2] = p2;
    assign products_flat[MAC_W*4-1:MAC_W*3] = p3;
    assign products_flat[MAC_W*5-1:MAC_W*4] = p4;

endmodule