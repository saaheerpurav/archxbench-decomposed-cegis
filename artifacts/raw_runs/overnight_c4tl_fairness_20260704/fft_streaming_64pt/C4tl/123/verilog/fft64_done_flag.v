`timescale 1ns/1ps

module fft64_done_flag (
    input valid_in,
    input last_in,
    output done
);
    assign done = valid_in & last_in;
endmodule