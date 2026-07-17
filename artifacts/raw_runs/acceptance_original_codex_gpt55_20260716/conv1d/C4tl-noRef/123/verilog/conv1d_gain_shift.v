`timescale 1ns/1ps

module conv1d_gain_shift #(
    parameter MAC_W  = 15,
    parameter OUT_W  = 12,
    parameter GAIN_W = 4
) (
    input  [MAC_W-1:0] mac_in,
    output [OUT_W-1:0] data_out
);

    assign data_out = mac_in[GAIN_W + OUT_W - 1:GAIN_W];

endmodule