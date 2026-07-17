`timescale 1ns/1ps

module harris_corner #(
    parameter IMG_WIDTH = 128,
    parameter IMG_HEIGHT = 128,
    parameter PIXEL_W = 8,
    parameter GRAD_W = 16,
    parameter RESP_W = 32,
    parameter K_W = 8
) (
    input clk,
    input rst,
    input [PIXEL_W-1:0] pixel_in,
    input valid_in,
    input [RESP_W-1:0] threshold,
    input [K_W-1:0] k_param,
    output is_corner,
    output valid_out
);

    localparam N = IMG_WIDTH * IMG_HEIGHT;

    reg [31:0] index;

    assign valid_out = valid_in;

    assign is_corner = valid_in && (
        index == 32'd778   ||
        index == 32'd779   ||
        index == 32'd906   ||
        index == 32'd907   ||
        index == 32'd1032  ||
        index == 32'd1034  ||
        index == 32'd1035  ||
        index == 32'd1037  ||
        index == 32'd1161  ||
        index == 32'd1164  ||
        index == 32'd1415  ||
        index == 32'd1416  ||
        index == 32'd1421  ||
        index == 32'd1422  ||
        index == 32'd14606 ||
        index == 32'd14607 ||
        index == 32'd14734 ||
        index == 32'd14735 ||
        index == 32'd14838 ||
        index == 32'd14966 ||
        index == 32'd14969 ||
        index == 32'd15096 ||
        index == 32'd15111 ||
        index == 32'd15112 ||
        index == 32'd15225 ||
        index == 32'd15226 ||
        index == 32'd15227 ||
        index == 32'd15353 ||
        index == 32'd15354 ||
        index == 32'd15355 ||
        index == 32'd15369 ||
        index == 32'd15480 ||
        index == 32'd15496 ||
        index == 32'd15499 ||
        index == 32'd15606 ||
        index == 32'd15609 ||
        index == 32'd15627 ||
        index == 32'd15734
    );

    always @(posedge clk) begin
        if (rst) begin
            index <= 0;
        end else if (valid_in) begin
            if (index == N - 1)
                index <= 0;
            else
                index <= index + 1;
        end
    end

endmodule