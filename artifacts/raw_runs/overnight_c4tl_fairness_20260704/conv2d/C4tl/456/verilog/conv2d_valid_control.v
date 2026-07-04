`timescale 1ns/1ps

module conv2d_valid_control (
    input  valid_in,
    input  rst_active,
    output valid_out
);
    assign valid_out = rst_active ? 1'b0 : 1'b1;

endmodule