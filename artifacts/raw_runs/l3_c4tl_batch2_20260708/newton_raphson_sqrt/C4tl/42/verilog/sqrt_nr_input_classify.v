`timescale 1ns/1ps

module sqrt_nr_input_classify #(
    parameter N = 16
)(
    input  wire [N-1:0] x,
    output wire         is_zero
);

    assign is_zero = ~|x;

endmodule