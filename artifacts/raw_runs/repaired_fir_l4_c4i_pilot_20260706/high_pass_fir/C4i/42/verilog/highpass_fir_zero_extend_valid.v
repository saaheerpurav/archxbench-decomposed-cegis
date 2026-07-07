`timescale 1ns/1ps

module highpass_fir_zero_extend_valid (
    input  valid_in,
    output valid_out
);

    assign valid_out = valid_in;

endmodule