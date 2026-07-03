`timescale 1ns/1ps

module conv1d_tap_select #(
    parameter DATA_W      = 8,
    parameter KERNEL_SIZE = 5
) (
    input [DATA_W-1:0] data_in,
    input [DATA_W-1:0] sample_0,
    input [DATA_W-1:0] sample_1,
    input [DATA_W-1:0] sample_2,
    input [DATA_W-1:0] sample_3,
    input [DATA_W-1:0] sample_4,
    input [DATA_W-1:0] sample_5,
    output [DATA_W-1:0] tap_0,
    output [DATA_W-1:0] tap_1,
    output [DATA_W-1:0] tap_2,
    output [DATA_W-1:0] tap_3,
    output [DATA_W-1:0] tap_4,
    output [DATA_W-1:0] tap_5,
    output [DATA_W-1:0] tap_6
);

    assign tap_0 = (KERNEL_SIZE >= 1) ? data_in  : {DATA_W{1'b0}};
    assign tap_1 = (KERNEL_SIZE >= 2) ? sample_0 : {DATA_W{1'b0}};
    assign tap_2 = (KERNEL_SIZE >= 3) ? sample_1 : {DATA_W{1'b0}};
    assign tap_3 = (KERNEL_SIZE >= 4) ? sample_2 : {DATA_W{1'b0}};
    assign tap_4 = (KERNEL_SIZE >= 5) ? sample_3 : {DATA_W{1'b0}};
    assign tap_5 = (KERNEL_SIZE >= 6) ? sample_4 : {DATA_W{1'b0}};
    assign tap_6 = (KERNEL_SIZE >= 7) ? sample_5 : {DATA_W{1'b0}};

endmodule