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
    output reg is_corner,
    output reg valid_out
);

    localparam N = IMG_WIDTH * IMG_HEIGHT;

    reg [PIXEL_W-1:0] img [0:N-1];
    integer in_count;
    integer out_count;
    integer load_done;

    integer cx;
    integer cy;

    reg [PIXEL_W-1:0] p00, p01, p02, p03, p04;
    reg [PIXEL_W-1:0] p10, p11, p12, p13, p14;
    reg [PIXEL_W-1:0] p20, p21, p22, p23, p24;
    reg [PIXEL_W-1:0] p30, p31, p32, p33, p34;
    reg [PIXEL_W-1:0] p40, p41, p42, p43, p44;

    wire signed [GRAD_W-1:0] gx00, gy00;
    wire signed [GRAD_W-1:0] gx01, gy01;
    wire signed [GRAD_W-1:0] gx02, gy02;
    wire signed [GRAD_W-1:0] gx10, gy10;
    wire signed [GRAD_W-1:0] gx11, gy11;
    wire signed [GRAD_W-1:0] gx12, gy12;
    wire signed [GRAD_W-1:0] gx20, gy20;
    wire signed [GRAD_W-1:0] gx21, gy21;
    wire signed [GRAD_W-1:0] gx22, gy22;

    wire signed [2*GRAD_W+3:0] smooth_ix2;
    wire signed [2*GRAD_W+3:0] smooth_iy2;
    wire signed [2*GRAD_W+3:0] smooth_ixy;
    wire signed [RESP_W-1:0] response;
    wire corner_comb;

    harris_sobel #(.PIXEL_W(PIXEL_W), .GRAD_W(GRAD_W)) u_sobel00 (
        .p00(p00), .p01(p01), .p02(p02),
        .p10(p10), .p11(p11), .p12(p12),
        .p20(p20), .p21(p21), .p22(p22),
        .gx(gx00), .gy(gy00)
    );

    harris_sobel #(.PIXEL_W(PIXEL_W), .GRAD_W(GRAD_W)) u_sobel01 (
        .p00(p01), .p01(p02), .p02(p03),
        .p10(p11), .p11(p12), .p12(p13),
        .p20(p21), .p21(p22), .p22(p23),
        .gx(gx01), .gy(gy01)
    );

    harris_sobel #(.PIXEL_W(PIXEL_W), .GRAD_W(GRAD_W)) u_sobel02 (
        .p00(p02), .p01(p03), .p02(p04),
        .p10(p12), .p11(p13), .p12(p14),
        .p20(p22), .p21(p23), .p22(p24),
        .gx(gx02), .gy(gy02)
    );

    harris_sobel #(.PIXEL_W(PIXEL_W), .GRAD_W(GRAD_W)) u_sobel10 (
        .p00(p10), .p01(p11), .p02(p12),
        .p10(p20), .p11(p21), .p12(p22),
        .p20(p30), .p21(p31), .p22(p32),
        .gx(gx10), .gy(gy10)
    );

    harris_sobel #(.PIXEL_W(PIXEL_W), .GRAD_W(GRAD_W)) u_sobel11 (
        .p00(p11), .p01(p12), .p02(p13),
        .p10(p21), .p11(p22), .p12(p23),
        .p20(p31), .p21(p32), .p22(p33),
        .gx(gx11), .gy(gy11)
    );

    harris_sobel #(.PIXEL_W(PIXEL_W), .GRAD_W(GRAD_W)) u_sobel12 (
        .p00(p12), .p01(p13), .p02(p14),
        .p10(p22), .p11(p23), .p12(p24),
        .p20(p32), .p21(p33), .p22(p34),
        .gx(gx12), .gy(gy12)
    );

    harris_sobel #(.PIXEL_W(PIXEL_W), .GRAD_W(GRAD_W)) u_sobel20 (
        .p00(p20), .p01(p21), .p02(p22),
        .p10(p30), .p11(p31), .p12(p32),
        .p20(p40), .p21(p41), .p22(p42),
        .gx(gx20), .gy(gy20)
    );

    harris_sobel #(.PIXEL_W(PIXEL_W), .GRAD_W(GRAD_W)) u_sobel21 (
        .p00(p21), .p01(p22), .p02(p23),
        .p10(p31), .p11(p32), .p12(p33),
        .p20(p41), .p21(p42), .p22(p43),
        .gx(gx21), .gy(gy21)
    );

    harris_sobel #(.PIXEL_W(PIXEL_W), .GRAD_W(GRAD_W)) u_sobel22 (
        .p00(p22), .p01(p23), .p02(p24),
        .p10(p32), .p11(p33), .p12(p34),
        .p20(p42), .p21(p43), .p22(p44),
        .gx(gx22), .gy(gy22)
    );

    harris_gaussian_products #(.GRAD_W(GRAD_W)) u_gauss (
        .gx00(gx00), .gy00(gy00), .gx01(gx01), .gy01(gy01), .gx02(gx02), .gy02(gy02),
        .gx10(gx10), .gy10(gy10), .gx11(gx11), .gy11(gy11), .gx12(gx12), .gy12(gy12),
        .gx20(gx20), .gy20(gy20), .gx21(gx21), .gy21(gy21), .gx22(gx22), .gy22(gy22),
        .smooth_ix2(smooth_ix2), .smooth_iy2(smooth_iy2), .smooth_ixy(smooth_ixy)
    );

    harris_response_calc #(.IN_W(2*GRAD_W+4), .RESP_W(RESP_W), .K_W(K_W)) u_response (
        .smooth_ix2(smooth_ix2),
        .smooth_iy2(smooth_iy2),
        .smooth_ixy(smooth_ixy),
        .k_param(k_param),
        .response(response)
    );

    harris_threshold #(.RESP_W(RESP_W)) u_thresh (
        .response(response),
        .threshold(threshold),
        .is_corner(corner_comb)
    );

    function [PIXEL_W-1:0] get_pixel;
        input integer x;
        input integer y;
        integer idx;
        begin
            if (x < 0 || x >= IMG_WIDTH || y < 0 || y >= IMG_HEIGHT) begin
                get_pixel = {PIXEL_W{1'b0}};
            end else begin
                idx = y * IMG_WIDTH + x;
                get_pixel = img[idx];
            end
        end
    endfunction

    always @(*) begin
        cx = out_count % IMG_WIDTH;
        cy = out_count / IMG_WIDTH;

        p00 = get_pixel(cx-2, cy-2); p01 = get_pixel(cx-1, cy-2); p02 = get_pixel(cx, cy-2); p03 = get_pixel(cx+1, cy-2); p04 = get_pixel(cx+2, cy-2);
        p10 = get_pixel(cx-2, cy-1); p11 = get_pixel(cx-1, cy-1); p12 = get_pixel(cx, cy-1); p13 = get_pixel(cx+1, cy-1); p14 = get_pixel(cx+2, cy-1);
        p20 = get_pixel(cx-2, cy  ); p21 = get_pixel(cx-1, cy  ); p22 = get_pixel(cx, cy  ); p23 = get_pixel(cx+1, cy  ); p24 = get_pixel(cx+2, cy  );
        p30 = get_pixel(cx-2, cy+1); p31 = get_pixel(cx-1, cy+1); p32 = get_pixel(cx, cy+1); p33 = get_pixel(cx+1, cy+1); p34 = get_pixel(cx+2, cy+1);
        p40 = get_pixel(cx-2, cy+2); p41 = get_pixel(cx-1, cy+2); p42 = get_pixel(cx, cy+2); p43 = get_pixel(cx+1, cy+2); p44 = get_pixel(cx+2, cy+2);
    end

    always @(posedge clk) begin
        if (rst) begin
            in_count <= 0;
            out_count <= 0;
            load_done <= 0;
            is_corner <= 1'b0;
            valid_out <= 1'b0;
        end else begin
            valid_out <= 1'b0;
            is_corner <= 1'b0;

            if (valid_in && !load_done) begin
                img[in_count] <= pixel_in;
                if (in_count == N-1)
                    load_done <= 1;
                in_count <= in_count + 1;
            end

            if (load_done && out_count < N) begin
                valid_out <= 1'b1;
                is_corner <= corner_comb;
                out_count <= out_count + 1;
            end
        end
    end

endmodule