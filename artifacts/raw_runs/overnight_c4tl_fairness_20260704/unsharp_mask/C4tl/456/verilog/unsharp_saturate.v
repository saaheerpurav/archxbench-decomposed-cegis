`timescale 1ns/1ps

module unsharp_saturate #(
    parameter PIXEL_W = 8,
    parameter SIGNED_W = PIXEL_W + 16
) (
    input signed [SIGNED_W-1:0] value_in,
    output [PIXEL_W-1:0] pixel_out
);
    localparam signed [SIGNED_W-1:0] MAX_VALUE = (1 << PIXEL_W) - 1;

    assign pixel_out = (value_in < 0) ? {PIXEL_W{1'b0}} :
                       (value_in > MAX_VALUE) ? {PIXEL_W{1'b1}} :
                       value_in[PIXEL_W-1:0];
endmodule