`timescale 1ns/1ps

module done_control(cycle_count, done_next);
    input [3:0] cycle_count;
    output done_next;

    assign done_next = (cycle_count >= 4'd8);
endmodule