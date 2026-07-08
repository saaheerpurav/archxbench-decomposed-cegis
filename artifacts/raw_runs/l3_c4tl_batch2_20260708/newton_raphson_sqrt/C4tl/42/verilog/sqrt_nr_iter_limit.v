`timescale 1ns/1ps

module sqrt_nr_iter_limit #(
    parameter ITER_MAX = 10
)(
    input  [$clog2(ITER_MAX+1)-1:0] iter_count,
    output iter_done
);

    assign iter_done = (iter_count >= ITER_MAX);

endmodule