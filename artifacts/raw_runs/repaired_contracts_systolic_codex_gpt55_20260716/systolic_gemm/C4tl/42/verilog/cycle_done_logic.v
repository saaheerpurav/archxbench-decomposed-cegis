`timescale 1ns/1ps

module cycle_done_logic(cycle_count, next_cycle_count, done_next);
    input [3:0] cycle_count;
    output [3:0] next_cycle_count;
    output done_next;

    assign next_cycle_count = (cycle_count < 4'd9) ? (cycle_count + 4'd1) : cycle_count;
    assign done_next = (cycle_count >= 4'd9);
endmodule