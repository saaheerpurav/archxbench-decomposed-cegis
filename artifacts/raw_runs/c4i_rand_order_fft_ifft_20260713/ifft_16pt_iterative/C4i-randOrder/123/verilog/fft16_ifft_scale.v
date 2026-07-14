`timescale 1ns/1ps

module fft16_ifft_scale #(
    parameter IN_W  = 16,
    parameter OUT_W = 16,
    parameter SHIFT = 4
) (
    input  signed [IN_W-1:0]  in_val,
    input                     do_scale,
    output signed [OUT_W-1:0] out_val
);

    wire signed [OUT_W-1:0] passthrough_val;
    wire signed [OUT_W-1:0] scaled_val;

    assign passthrough_val = in_val;
    assign scaled_val      = in_val >>> SHIFT;

    assign out_val = do_scale ? scaled_val : passthrough_val;

endmodule