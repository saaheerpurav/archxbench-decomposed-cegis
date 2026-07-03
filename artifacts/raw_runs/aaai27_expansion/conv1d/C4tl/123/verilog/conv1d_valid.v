`timescale 1ns/1ps

module conv1d_valid #(
    parameter DATA_W = 8
) (
    input  valid_in,
    output valid_out
);

    assign valid_out = valid_in;

endmodule