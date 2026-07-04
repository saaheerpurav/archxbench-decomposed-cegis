`timescale 1ns/1ps

module conv2d_position #(
    parameter IMG_WIDTH = 64
) (
    input  [31:0] row_in,
    input  [31:0] col_in,
    input         valid_in,
    output [31:0] row_out,
    output [31:0] col_out,
    output        end_of_line
);

    assign end_of_line = valid_in && (col_in == (IMG_WIDTH - 1));

    assign col_out = !valid_in   ? col_in :
                     end_of_line ? 32'd0  :
                                   col_in + 32'd1;

    assign row_out = !valid_in   ? row_in :
                     end_of_line ? row_in + 32'd1 :
                                   row_in;

endmodule