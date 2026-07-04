`timescale 1ns/1ps

module fft_counter_next #(
    parameter POINTS = 64
) (
    input  [5:0] count_in,
    input        valid_in,
    input        last_in,
    output [5:0] count_out,
    output       frame_last
);

    localparam [5:0] TERMINAL_COUNT = POINTS[5:0] - 6'd1;

    assign frame_last = valid_in && (last_in || (count_in == TERMINAL_COUNT));

    assign count_out = valid_in
                     ? (frame_last ? 6'd0 : count_in + 6'd1)
                     : count_in;

endmodule