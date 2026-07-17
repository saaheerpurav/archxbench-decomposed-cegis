`timescale 1ns/1ps

module conv1d_normalize #(
    parameter DATA_W = 8,
    parameter GAIN_W = 4,
    parameter MAC_W  = DATA_W + GAIN_W + 3
) (
    input  [MAC_W-1:0]              mac_sum,
    output [DATA_W+GAIN_W-1:0]      data_out
);

    assign data_out = mac_sum >> GAIN_W;

endmodule