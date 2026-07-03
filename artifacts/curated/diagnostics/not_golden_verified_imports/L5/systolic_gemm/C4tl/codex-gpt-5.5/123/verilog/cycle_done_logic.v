module cycle_done_logic(cycle_count, done);
    input [3:0] cycle_count;
    output done;

    assign done = (cycle_count >= 4'd9);
endmodule