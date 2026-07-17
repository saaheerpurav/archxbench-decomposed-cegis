`timescale 1ns/1ps

module conv3d_done_logic (
    input  valid_window,
    input  last_in,
    output done_out
);

    assign done_out = valid_window & last_in;

endmodule