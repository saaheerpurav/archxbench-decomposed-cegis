`timescale 1ns/1ps

module saturate_pixel #(
    parameter PIXEL_W = 8,
    parameter IN_W = 29
) (
    input signed [IN_W-1:0] value,
    output [PIXEL_W-1:0] pixel
);
    localparam [PIXEL_W-1:0] MAX_PIXEL = {PIXEL_W{1'b1}};

    assign pixel = (value < 0) ? {PIXEL_W{1'b0}} :
                   (value > $signed({1'b0, MAX_PIXEL})) ? MAX_PIXEL :
                   value[PIXEL_W-1:0];
endmodule