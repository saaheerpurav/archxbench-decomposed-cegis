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
    localparam IDX_W = 15;

    reg [PIXEL_W-1:0] frame [0:N-1];

    reg [IDX_W-1:0] in_count;
    reg [IDX_W-1:0] out_count;
    reg loading_done;
    reg out_valid_r;
    reg is_corner_r;

    assign valid_out = out_valid_r;
    assign is_corner = is_corner_r;

    wire [IDX_W-1:0] row = out_count / IMG_WIDTH;
    wire [IDX_W-1:0] col = out_count % IMG_WIDTH;

    function [PIXEL_W-1:0] pix_at;
        input integer rr;
        input integer cc;
        integer idx;
        begin
            if (rr < 0 || rr >= IMG_HEIGHT || cc < 0 || cc >= IMG_WIDTH) begin
                pix_at = {PIXEL_W{1'b0}};
            end else begin
                idx = rr * IMG_WIDTH + cc;
                pix_at = frame[idx];
            end
        end
    endfunction

    wire [PIXEL_W-1:0] p00 = pix_at(row-1, col-1);
    wire [PIXEL_W-1:0] p01 = pix_at(row-1, col);
    wire [PIXEL_W-1:0] p02 = pix_at(row-1, col+1);
    wire [PIXEL_W-1:0] p10 = pix_at(row,   col-1);
    wire [PIXEL_W-1:0] p11 = pix_at(row,   col);
    wire [PIXEL_W-1:0] p12 = pix_at(row,   col+1);
    wire [PIXEL_W-1:0] p20 = pix_at(row+1, col-1);
    wire [PIXEL_W-1:0] p21 = pix_at(row+1, col);
    wire [PIXEL_W-1:0] p22 = pix_at(row+1, col+1);

    wire signed [GRAD_W-1:0] ix;
    wire signed [GRAD_W-1:0] iy;

    harris_sobel3x3 #(
        .PIXEL_W(PIXEL_W),
        .GRAD_W(GRAD_W)
    ) u_sobel (
        .p00(p00), .p01(p01), .p02(p02),
        .p10(p10), .p11(p11), .p12(p12),
        .p20(p20), .p21(p21), .p22(p22),
        .gx(ix),
        .gy(iy)
    );

    wire [2*GRAD_W-1:0] ix2;
    wire [2*GRAD_W-1:0] iy2;
    wire signed [2*GRAD_W-1:0] ixiy;

    harris_gradient_products #(
        .GRAD_W(GRAD_W)
    ) u_products (
        .ix(ix),
        .iy(iy),
        .ix2(ix2),
        .iy2(iy2),
        .ixiy(ixiy)
    );

    wire [2*GRAD_W-1:0] sx2;
    wire [2*GRAD_W-1:0] sy2;
    wire signed [2*GRAD_W-1:0] sxy;

    harris_gaussian_passthrough #(
        .PROD_W(2*GRAD_W)
    ) u_smooth (
        .ix2_in(ix2),
        .iy2_in(iy2),
        .ixiy_in(ixiy),
        .ix2_out(sx2),
        .iy2_out(sy2),
        .ixiy_out(sxy)
    );

    wire signed [RESP_W-1:0] response;

    harris_response #(
        .PROD_W(2*GRAD_W),
        .RESP_W(RESP_W),
        .K_W(K_W)
    ) u_response (
        .ix2(sx2),
        .iy2(sy2),
        .ixiy(sxy),
        .k_param(k_param),
        .response(response)
    );

    wire corner_comb;

    harris_threshold #(
        .RESP_W(RESP_W)
    ) u_threshold (
        .response(response),
        .threshold(threshold),
        .is_corner(corner_comb)
    );

    always @(posedge clk) begin
        if (rst) begin
            in_count <= 0;
            out_count <= 0;
            loading_done <= 1'b0;
            out_valid_r <= 1'b0;
            is_corner_r <= 1'b0;
        end else begin
            out_valid_r <= 1'b0;

            if (valid_in && !loading_done) begin
                frame[in_count] <= pixel_in;
                if (in_count == N-1) begin
                    loading_done <= 1'b1;
                    in_count <= in_count;
                end else begin
                    in_count <= in_count + 1'b1;
                end
            end

            if (loading_done && out_count < N) begin
                out_valid_r <= 1'b1;
                is_corner_r <= corner_comb;
                out_count <= out_count + 1'b1;
            end
        end
    end

endmodule