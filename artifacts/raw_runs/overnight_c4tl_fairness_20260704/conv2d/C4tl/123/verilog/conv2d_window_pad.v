`timescale 1ns/1ps

module conv2d_window_pad #(
    parameter DATA_W      = 8,
    parameter KERNEL_SIZE = 3
) (
    input  [KERNEL_SIZE*KERNEL_SIZE*DATA_W-1:0] window_in,
    input                                       pad_top,
    input                                       pad_left,
    output reg [KERNEL_SIZE*KERNEL_SIZE*DATA_W-1:0] window_out
);

    integer r, c;
    integer idx;

    always @* begin
        window_out = window_in;

        for (r = 0; r < KERNEL_SIZE; r = r + 1) begin
            for (c = 0; c < KERNEL_SIZE; c = c + 1) begin
                idx = r*KERNEL_SIZE + c;
                if ((pad_top && r == KERNEL_SIZE-1) ||
                    (pad_left && c == KERNEL_SIZE-1)) begin
                    window_out[(idx+1)*DATA_W-1 -: DATA_W] = {DATA_W{1'b0}};
                end
            end
        end
    end

endmodule