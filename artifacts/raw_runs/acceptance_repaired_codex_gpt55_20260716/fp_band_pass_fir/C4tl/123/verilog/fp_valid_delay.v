`timescale 1ns/1ps

module fp_valid_delay #(
    parameter LATENCY = 0
) (
    input wire valid_i,
    output wire valid_o
);

  assign valid_o = valid_i;

endmodule