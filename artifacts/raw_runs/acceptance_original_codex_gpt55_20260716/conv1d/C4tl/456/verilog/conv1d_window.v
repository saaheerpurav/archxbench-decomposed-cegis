`timescale 1ns/1ps

module conv1d_window #(
    parameter DATA_W = 8
) (
    input  [DATA_W-1:0]   x0,
    input  [DATA_W-1:0]   x1,
    input  [DATA_W-1:0]   x2,
    input  [DATA_W-1:0]   x3,
    input  [DATA_W-1:0]   x4,
    output [DATA_W*5-1:0] window_flat
);

    assign window_flat = {x4, x3, x2, x1, x0};

endmodule