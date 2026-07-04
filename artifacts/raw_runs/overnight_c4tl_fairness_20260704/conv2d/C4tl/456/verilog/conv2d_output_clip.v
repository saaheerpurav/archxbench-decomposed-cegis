`timescale 1ns/1ps

module conv2d_output_clip #(
    parameter IN_W  = 20,
    parameter OUT_W = 12
) (
    input      [IN_W-1:0]  value_in,
    output     [OUT_W-1:0] value_out
);
    wire overflow;
    assign overflow = |value_in[IN_W-1:OUT_W];
    assign value_out = overflow ? {OUT_W{1'b1}} : value_in[OUT_W-1:0];

endmodule