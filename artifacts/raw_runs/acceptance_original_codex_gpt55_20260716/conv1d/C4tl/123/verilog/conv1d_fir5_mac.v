`timescale 1ns/1ps

module conv1d_fir5_mac #(
    parameter DATA_W      = 8,
    parameter KERNEL_SIZE = 5,
    parameter GAIN_W      = 4
) (
    input  [DATA_W-1:0] tap0,
    input  [DATA_W-1:0] tap1,
    input  [DATA_W-1:0] tap2,
    input  [DATA_W-1:0] tap3,
    input  [DATA_W-1:0] tap4,
    output [DATA_W+GAIN_W+$clog2(KERNEL_SIZE)-1:0] mac_sum
);

    localparam MAC_W = DATA_W + GAIN_W + $clog2(KERNEL_SIZE);

    wire [MAC_W-1:0] tap0_ext = {{(MAC_W-DATA_W){1'b0}}, tap0};
    wire [MAC_W-1:0] tap1_ext = {{(MAC_W-DATA_W){1'b0}}, tap1};
    wire [MAC_W-1:0] tap2_ext = {{(MAC_W-DATA_W){1'b0}}, tap2};
    wire [MAC_W-1:0] tap3_ext = {{(MAC_W-DATA_W){1'b0}}, tap3};
    wire [MAC_W-1:0] tap4_ext = {{(MAC_W-DATA_W){1'b0}}, tap4};

    assign mac_sum =
        (tap0_ext << 1) +
        (tap1_ext << 3) +
        ((tap2_ext << 3) + (tap2_ext << 2)) +
        (tap3_ext << 3) +
        (tap4_ext << 1);

endmodule