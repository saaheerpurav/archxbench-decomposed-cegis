`timescale 1ns/1ps

module conv3d_stream_index #(
    parameter D = 8,
    parameter H = 64,
    parameter W = 64,
    parameter COUNT_W = 32
) (
    input  [COUNT_W-1:0] linear_index,
    output [COUNT_W-1:0] x_pos,
    output [COUNT_W-1:0] y_pos,
    output [COUNT_W-1:0] z_pos,
    output input_ready
);

    localparam FRAME_SIZE = H * W;
    localparam TOTAL_SIZE = D * H * W;

    assign x_pos = linear_index % W;
    assign y_pos = (linear_index / W) % H;
    assign z_pos = linear_index / FRAME_SIZE;

    assign input_ready = (linear_index < TOTAL_SIZE);

endmodule