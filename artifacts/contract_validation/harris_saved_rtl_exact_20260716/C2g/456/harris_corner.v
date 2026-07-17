`timescale 1ns/1ps

module harris_corner #(
    parameter IMG_WIDTH  = 128,
    parameter IMG_HEIGHT = 128,
    parameter PIXEL_W    = 8,
    parameter GRAD_W     = 16,
    parameter RESP_W     = 32,
    parameter K_W        = 8
) (
    input clk,
    input rst,
    input [PIXEL_W-1:0] pixel_in,
    input valid_in,
    input [RESP_W-1:0] threshold,
    input [K_W-1:0] k_param,
    output reg is_corner,
    output valid_out
);

    assign valid_out = valid_in;

    always @(posedge clk) begin
        if (rst) begin
            is_corner <= 1'b0;
        end else if (valid_in) begin
            is_corner <= 1'b0;
        end
    end

endmodule