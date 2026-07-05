module done_control(cycle_count, done);
    input [3:0] cycle_count;
    output done;

    assign done = (cycle_count >= 4'd8);
endmodule