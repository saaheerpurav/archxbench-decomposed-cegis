`timescale 1ns/1ps

module fir_tap_pair_adder #(
    parameter DATA_W = 20
) (
    input  signed [DATA_W-1:0] sample_a,
    input  signed [DATA_W-1:0] sample_b,
    output signed [DATA_W:0]   pair_sum
);

    assign pair_sum =
        $signed({sample_a[DATA_W-1], sample_a}) +
        $signed({sample_b[DATA_W-1], sample_b});

endmodule