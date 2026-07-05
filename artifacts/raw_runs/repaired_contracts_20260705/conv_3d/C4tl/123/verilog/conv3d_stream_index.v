`timescale 1ns/1ps

module conv3d_stream_index #(
    parameter H = 64,
    parameter W = 64
) (
    input [31:0] linear_index,
    output [31:0] depth_idx,
    output [31:0] row_idx,
    output [31:0] col_idx
);

    wire [63:0] linear_index_ext;
    wire [63:0] h_ext;
    wire [63:0] w_ext;
    wire [63:0] plane_size;

    assign linear_index_ext = {32'd0, linear_index};
    assign h_ext = H;
    assign w_ext = W;
    assign plane_size = h_ext * w_ext;

    assign depth_idx = linear_index_ext / plane_size;
    assign row_idx   = (linear_index_ext / w_ext) % h_ext;
    assign col_idx   = linear_index_ext % w_ext;

endmodule