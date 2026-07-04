`timescale 1ns/1ps

module conv3d_line_buffer_model #(
    parameter DATA_W = 8
) (
    input  [DATA_W-1:0] in_value,
    output [DATA_W-1:0] out_value
);

    assign out_value = in_value;

endmodule