`timescale 1ns/1ps

module conv1d_mac #(
    parameter DATA_W = 8,
    parameter GAIN_W = 4
) (
    input  [DATA_W-1:0]              x0,
    input  [DATA_W-1:0]              x1,
    input  [DATA_W-1:0]              x2,
    input  [DATA_W-1:0]              x3,
    input  [DATA_W-1:0]              x4,
    output [DATA_W+GAIN_W+3-1:0]     mac_sum
);

    localparam MAC_W = DATA_W + GAIN_W + 3;

    wire [MAC_W-1:0] x0_ext = {{(MAC_W-DATA_W){1'b0}}, x0};
    wire [MAC_W-1:0] x1_ext = {{(MAC_W-DATA_W){1'b0}}, x1};
    wire [MAC_W-1:0] x2_ext = {{(MAC_W-DATA_W){1'b0}}, x2};
    wire [MAC_W-1:0] x3_ext = {{(MAC_W-DATA_W){1'b0}}, x3};
    wire [MAC_W-1:0] x4_ext = {{(MAC_W-DATA_W){1'b0}}, x4};

    assign mac_sum =
          (x0_ext << 1)
        + (x1_ext << 3)
        + ((x2_ext << 3) + (x2_ext << 2))
        + (x3_ext << 3)
        + (x4_ext << 1);

endmodule