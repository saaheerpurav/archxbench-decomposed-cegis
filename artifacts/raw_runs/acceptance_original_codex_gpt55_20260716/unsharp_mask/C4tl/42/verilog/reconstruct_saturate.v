`timescale 1ns/1ps

module reconstruct_saturate #(
    parameter PIXEL_W = 8,
    parameter PROD_W = 18,
    parameter ACC_W = PROD_W + 2
) (
    input [PIXEL_W-1:0] original,
    input signed [PROD_W-1:0] scaled_high,
    output [PIXEL_W-1:0] pixel_out
);
    wire signed [ACC_W-1:0] acc;
    assign acc = $signed({1'b0, original}) + scaled_high;

    assign pixel_out = (acc < 0) ? {PIXEL_W{1'b0}} :
                       (acc > ((1 << PIXEL_W) - 1)) ? {PIXEL_W{1'b1}} :
                       acc[PIXEL_W-1:0];
endmodule