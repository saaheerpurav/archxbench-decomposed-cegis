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

    integer i;

    reg [PIXEL_W-1:0] line0 [0:IMG_WIDTH-1];
    reg [PIXEL_W-1:0] line1 [0:IMG_WIDTH-1];

    reg [PIXEL_W-1:0] r0c0, r0c1, r0c2;
    reg [PIXEL_W-1:0] r1c0, r1c1, r1c2;
    reg [PIXEL_W-1:0] r2c0, r2c1, r2c2;

    reg [31:0] x_pos;
    reg [31:0] y_pos;

    wire signed [GRAD_W-1:0] grad_x;
    wire signed [GRAD_W-1:0] grad_y;

    wire [2*GRAD_W-1:0] ix2_raw;
    wire [2*GRAD_W-1:0] iy2_raw;
    wire signed [2*GRAD_W-1:0] ixy_raw;

    wire [2*GRAD_W+3:0] ix2_smooth;
    wire [2*GRAD_W+3:0] iy2_smooth;
    wire signed [2*GRAD_W+3:0] ixy_smooth;

    wire signed [RESP_W-1:0] response;
    wire decision;

    wire border_pixel;
    assign border_pixel = (x_pos < 2) || (y_pos < 2) ||
                          (x_pos >= IMG_WIDTH) || (y_pos >= IMG_HEIGHT);

    harris_sobel_3x3 #(
        .PIXEL_W(PIXEL_W),
        .GRAD_W(GRAD_W)
    ) u_sobel (
        .p00(r0c0), .p01(r0c1), .p02(r0c2),
        .p10(r1c0), .p11(r1c1), .p12(r1c2),
        .p20(r2c0), .p21(r2c1), .p22(pixel_in),
        .grad_x(grad_x),
        .grad_y(grad_y)
    );

    harris_gradient_products #(
        .GRAD_W(GRAD_W)
    ) u_products (
        .grad_x(grad_x),
        .grad_y(grad_y),
        .ix2(ix2_raw),
        .iy2(iy2_raw),
        .ixy(ixy_raw)
    );

    harris_gaussian_approx #(
        .IN_W(2*GRAD_W),
        .OUT_W(2*GRAD_W+4)
    ) u_gaussian (
        .ix2_in(ix2_raw),
        .iy2_in(iy2_raw),
        .ixy_in(ixy_raw),
        .ix2_out(ix2_smooth),
        .iy2_out(iy2_smooth),
        .ixy_out(ixy_smooth)
    );

    harris_response_calc #(
        .IN_W(2*GRAD_W+4),
        .RESP_W(RESP_W),
        .K_W(K_W)
    ) u_response (
        .ix2(ix2_smooth),
        .iy2(iy2_smooth),
        .ixy(ixy_smooth),
        .k_param(k_param),
        .response(response)
    );

    harris_threshold #(
        .RESP_W(RESP_W)
    ) u_threshold (
        .response(response),
        .threshold(threshold),
        .suppress(border_pixel),
        .is_corner(decision)
    );

    assign is_corner = valid_in ? decision : 1'b0;
    assign valid_out = valid_in;

    always @(posedge clk) begin
        if (rst) begin
            x_pos <= 0;
            y_pos <= 0;

            r0c0 <= 0; r0c1 <= 0; r0c2 <= 0;
            r1c0 <= 0; r1c1 <= 0; r1c2 <= 0;
            r2c0 <= 0; r2c1 <= 0; r2c2 <= 0;

            for (i = 0; i < IMG_WIDTH; i = i + 1) begin
                line0[i] <= 0;
                line1[i] <= 0;
            end
        end else if (valid_in) begin
            r0c0 <= r0c1;
            r0c1 <= r0c2;
            r0c2 <= line1[x_pos];

            r1c0 <= r1c1;
            r1c1 <= r1c2;
            r1c2 <= line0[x_pos];

            r2c0 <= r2c1;
            r2c1 <= r2c2;
            r2c2 <= pixel_in;

            line1[x_pos] <= line0[x_pos];
            line0[x_pos] <= pixel_in;

            if (x_pos == IMG_WIDTH-1) begin
                x_pos <= 0;
                if (y_pos == IMG_HEIGHT-1)
                    y_pos <= 0;
                else
                    y_pos <= y_pos + 1;
            end else begin
                x_pos <= x_pos + 1;
            end
        end
    end

endmodule