`timescale 1ns/1ps

module conv1d_shift_window #(
    parameter DATA_W      = 8,
    parameter KERNEL_SIZE = 5
) (
    input  [DATA_W*KERNEL_SIZE-1:0] window_in,
    input  [DATA_W-1:0]             sample_in,
    output [DATA_W*KERNEL_SIZE-1:0] window_out
);

generate
    if (KERNEL_SIZE == 1) begin : gen_single_tap
        assign window_out = sample_in;
    end else begin : gen_shift_window
        assign window_out = {
            window_in[DATA_W*(KERNEL_SIZE-1)-1:0],
            sample_in
        };
    end
endgenerate

endmodule