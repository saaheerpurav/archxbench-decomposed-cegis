`timescale 1ns/1ps

module conv1d_mac5 #(
    parameter DATA_W = 8,
    parameter MAC_W  = 15
) (
    input  [DATA_W-1:0] x0,
    input  [DATA_W-1:0] x1,
    input  [DATA_W-1:0] x2,
    input  [DATA_W-1:0] x3,
    input  [DATA_W-1:0] x4,
    output [MAC_W-1:0]  mac_out
);

    wire [MAC_W-1:0] p0;
    wire [MAC_W-1:0] p1;
    wire [MAC_W-1:0] p2;
    wire [MAC_W-1:0] p3;
    wire [MAC_W-1:0] p4;

    assign p0 = {{(MAC_W-DATA_W){1'b0}}, x0} * 4'd2;
    assign p1 = {{(MAC_W-DATA_W){1'b0}}, x1} * 4'd8;
    assign p2 = {{(MAC_W-DATA_W){1'b0}}, x2} * 4'd12;
    assign p3 = {{(MAC_W-DATA_W){1'b0}}, x3} * 4'd8;
    assign p4 = {{(MAC_W-DATA_W){1'b0}}, x4} * 4'd2;

    assign mac_out = p0 + p1 + p2 + p3 + p4;

endmodule