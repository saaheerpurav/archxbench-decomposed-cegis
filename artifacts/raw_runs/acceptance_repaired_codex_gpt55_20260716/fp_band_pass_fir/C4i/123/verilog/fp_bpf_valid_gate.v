`timescale 1ns/1ps

module fp_bpf_valid_gate (
    input wire valid_in,
    output wire valid_out
);
    assign #11 valid_out = valid_in;
endmodule