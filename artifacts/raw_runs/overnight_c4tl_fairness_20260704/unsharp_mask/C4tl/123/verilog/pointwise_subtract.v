`timescale 1ns/1ps

module pointwise_subtract #(
    parameter PIXEL_W = 8
) (
    input [PIXEL_W-1:0] original_pixel,
    input [PIXEL_W-1:0] blur_pixel,
    output signed [PIXEL_W:0] high_freq
);

    assign high_freq = $signed({1'b0, original_pixel}) - $signed({1'b0, blur_pixel});

endmodule