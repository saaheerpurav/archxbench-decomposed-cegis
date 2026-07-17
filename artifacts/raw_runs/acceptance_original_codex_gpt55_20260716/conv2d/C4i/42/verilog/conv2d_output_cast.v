`timescale 1ns/1ps

module conv2d_output_cast #(
    parameter ACC_W = 20,
    parameter OUT_W = 12
) (
    input  signed [ACC_W-1:0] sum,
    output [OUT_W-1:0]        pixel_out
);

    assign pixel_out = sum[OUT_W-1:0];

endmodule