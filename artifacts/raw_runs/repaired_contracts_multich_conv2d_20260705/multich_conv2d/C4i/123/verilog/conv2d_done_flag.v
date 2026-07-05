`timescale 1ns/1ps

module conv2d_done_flag #(
    parameter OUT_N = 30752,
    parameter OUT_IDX_W = 15
)(
    input emitted_last,
    output done
);

    assign done = emitted_last;

endmodule