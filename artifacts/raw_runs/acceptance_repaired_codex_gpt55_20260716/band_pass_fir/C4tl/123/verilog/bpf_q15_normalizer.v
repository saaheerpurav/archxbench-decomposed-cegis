`timescale 1ns/1ps

module bpf_q15_normalizer #(
    parameter OUT_W = 24
) (
    input  signed [63:0]       acc_in,
    output signed [OUT_W-1:0]  data_out
);

    assign data_out = (acc_in >>> 15);

endmodule