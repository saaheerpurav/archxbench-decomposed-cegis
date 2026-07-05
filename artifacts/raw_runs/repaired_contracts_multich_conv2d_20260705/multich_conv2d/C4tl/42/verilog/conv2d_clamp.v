`timescale 1ns/1ps

module conv2d_clamp #(
    parameter ACC_W = 32,
    parameter OUT_W = 16
)(
    input  [ACC_W-1:0] value_in,
    output [OUT_W-1:0] value_out
);

    wire [ACC_W-1:0] max_out;

    assign max_out = {{(ACC_W-OUT_W){1'b0}}, {OUT_W{1'b1}}};

    assign value_out = (value_in > max_out)
        ? {OUT_W{1'b1}}
        : value_in[OUT_W-1:0];

endmodule