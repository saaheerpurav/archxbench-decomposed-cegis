`timescale 1ns/1ps

module fp_output_select (
    input wire valid_i,
    input wire [31:0] data_i,
    output wire [31:0] data_o
);

  assign data_o = valid_i ? data_i : 32'h00000000;

endmodule