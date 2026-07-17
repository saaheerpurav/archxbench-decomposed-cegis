`timescale 1ns/1ps

module hp_valid_delay #(
    parameter DEPTH = 100
) (
    input wire [DEPTH:0] valid_pipe,
    output wire valid_out
);
  assign valid_out = valid_pipe[DEPTH];
endmodule