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
    localparam PROD_W = (2*GRAD_W) + 1;
    localparam SMOOTH_W = PROD_W + 5;

    reg [PIXEL_W-1:0] img [0:N-1];

    reg [$clog2(N+1)-1:0] in_count;
    reg [$clog2(N+1)-1:0] out_count;
    reg streaming_done;
    reg valid_r;
    reg corner_r;

    assign valid_out = valid_r;
    assign is_corner = corner_r;

    wire [$clog2(IMG_WIDTH)-1:0] cur_x;
    wire [$clog2(IMG_HEIGHT)-1:0] cur_y;

    harris_index_to_xy #(
        .IMG_WIDTH(IMG_WIDTH),
        .IMG_HEIGHT(IMG_HEIGHT)
    ) u_xy (
        .idx(out_count[$clog2(N)-1:0]),
        .x(cur_x),
        .y(cur_y)
    );

    function [PIXEL_W-1:0] get_pixel;
        input integer x;
        input integer y;
        begin
            if (x < 0 || x >= IMG_WIDTH || y < 0 || y >= IMG_HEIGHT)
                get_pixel = {PIXEL_W{1'b0}};
            else
                get_pixel = img[(y * IMG_WIDTH) + x];
        end
    endfunction

    wire signed [GRAD_W-1:0] gx00, gy00, gx01, gy01, gx02, gy02;
    wire signed [GRAD_W-1:0] gx10, gy10, gx11, gy11, gx12, gy12;
    wire signed [GRAD_W-1:0] gx20, gy20, gx21, gy21, gx22, gy22;

    harris_sobel #(.PIXEL_W(PIXEL_W), .GRAD_W(GRAD_W)) u_sobel00 (
        .p00(get_pixel(cur_x-2, cur_y-2)), .p01(get_pixel(cur_x-1, cur_y-2)), .p02(get_pixel(cur_x,   cur_y-2)),
        .p10(get_pixel(cur_x-2, cur_y-1)), .p11(get_pixel(cur_x-1, cur_y-1)), .p12(get_pixel(cur_x,   cur_y-1)),
        .p20(get_pixel(cur_x-2, cur_y  )), .p21(get_pixel(cur_x-1, cur_y  )), .p22(get_pixel(cur_x,   cur_y  )),
        .gx(gx00), .gy(gy00)
    );

    harris_sobel #(.PIXEL_W(PIXEL_W), .GRAD_W(GRAD_W)) u_sobel01 (
        .p00(get_pixel(cur_x-1, cur_y-2)), .p01(get_pixel(cur_x, cur_y-2)), .p02(get_pixel(cur_x+1, cur_y-2)),
        .p10(get_pixel(cur_x-1, cur_y-1)), .p11(get_pixel(cur_x, cur_y-1)), .p12(get_pixel(cur_x+1, cur_y-1)),
        .p20(get_pixel(cur_x-1, cur_y  )), .p21(get_pixel(cur_x, cur_y  )), .p22(get_pixel(cur_x+1, cur_y  )),
        .gx(gx01), .gy(gy01)
    );

    harris_sobel #(.PIXEL_W(PIXEL_W), .GRAD_W(GRAD_W)) u_sobel02 (
        .p00(get_pixel(cur_x, cur_y-2)), .p01(get_pixel(cur_x+1, cur_y-2)), .p02(get_pixel(cur_x+2, cur_y-2)),
        .p10(get_pixel(cur_x, cur_y-1)), .p11(get_pixel(cur_x+1, cur_y-1)), .p12(get_pixel(cur_x+2, cur_y-1)),
        .p20(get_pixel(cur_x, cur_y  )), .p21(get_pixel(cur_x+1, cur_y  )), .p22(get_pixel(cur_x+2, cur_y  )),
        .gx(gx02), .gy(gy02)
    );

    harris_sobel #(.PIXEL_W(PIXEL_W), .GRAD_W(GRAD_W)) u_sobel10 (
        .p00(get_pixel(cur_x-2, cur_y-1)), .p01(get_pixel(cur_x-1, cur_y-1)), .p02(get_pixel(cur_x,   cur_y-1)),
        .p10(get_pixel(cur_x-2, cur_y  )), .p11(get_pixel(cur_x-1, cur_y  )), .p12(get_pixel(cur_x,   cur_y  )),
        .p20(get_pixel(cur_x-2, cur_y+1)), .p21(get_pixel(cur_x-1, cur_y+1)), .p22(get_pixel(cur_x,   cur_y+1)),
        .gx(gx10), .gy(gy10)
    );

    harris_sobel #(.PIXEL_W(PIXEL_W), .GRAD_W(GRAD_W)) u_sobel11 (
        .p00(get_pixel(cur_x-1, cur_y-1)), .p01(get_pixel(cur_x, cur_y-1)), .p02(get_pixel(cur_x+1, cur_y-1)),
        .p10(get_pixel(cur_x-1, cur_y  )), .p11(get_pixel(cur_x, cur_y  )), .p12(get_pixel(cur_x+1, cur_y  )),
        .p20(get_pixel(cur_x-1, cur_y+1)), .p21(get_pixel(cur_x, cur_y+1)), .p22(get_pixel(cur_x+1, cur_y+1)),
        .gx(gx11), .gy(gy11)
    );

    harris_sobel #(.PIXEL_W(PIXEL_W), .GRAD_W(GRAD_W)) u_sobel12 (
        .p00(get_pixel(cur_x, cur_y-1)), .p01(get_pixel(cur_x+1, cur_y-1)), .p02(get_pixel(cur_x+2, cur_y-1)),
        .p10(get_pixel(cur_x, cur_y  )), .p11(get_pixel(cur_x+1, cur_y  )), .p12(get_pixel(cur_x+2, cur_y  )),
        .p20(get_pixel(cur_x, cur_y+1)), .p21(get_pixel(cur_x+1, cur_y+1)), .p22(get_pixel(cur_x+2, cur_y+1)),
        .gx(gx12), .gy(gy12)
    );

    harris_sobel #(.PIXEL_W(PIXEL_W), .GRAD_W(GRAD_W)) u_sobel20 (
        .p00(get_pixel(cur_x-2, cur_y)), .p01(get_pixel(cur_x-1, cur_y)), .p02(get_pixel(cur_x,   cur_y)),
        .p10(get_pixel(cur_x-2, cur_y+1)), .p11(get_pixel(cur_x-1, cur_y+1)), .p12(get_pixel(cur_x,   cur_y+1)),
        .p20(get_pixel(cur_x-2, cur_y+2)), .p21(get_pixel(cur_x-1, cur_y+2)), .p22(get_pixel(cur_x,   cur_y+2)),
        .gx(gx20), .gy(gy20)
    );

    harris_sobel #(.PIXEL_W(PIXEL_W), .GRAD_W(GRAD_W)) u_sobel21 (
        .p00(get_pixel(cur_x-1, cur_y)), .p01(get_pixel(cur_x, cur_y)), .p02(get_pixel(cur_x+1, cur_y)),
        .p10(get_pixel(cur_x-1, cur_y+1)), .p11(get_pixel(cur_x, cur_y+1)), .p12(get_pixel(cur_x+1, cur_y+1)),
        .p20(get_pixel(cur_x-1, cur_y+2)), .p21(get_pixel(cur_x, cur_y+2)), .p22(get_pixel(cur_x+1, cur_y+2)),
        .gx(gx21), .gy(gy21)
    );

    harris_sobel #(.PIXEL_W(PIXEL_W), .GRAD_W(GRAD_W)) u_sobel22 (
        .p00(get_pixel(cur_x, cur_y)), .p01(get_pixel(cur_x+1, cur_y)), .p02(get_pixel(cur_x+2, cur_y)),
        .p10(get_pixel(cur_x, cur_y+1)), .p11(get_pixel(cur_x+1, cur_y+1)), .p12(get_pixel(cur_x+2, cur_y+1)),
        .p20(get_pixel(cur_x, cur_y+2)), .p21(get_pixel(cur_x+1, cur_y+2)), .p22(get_pixel(cur_x+2, cur_y+2)),
        .gx(gx22), .gy(gy22)
    );

    wire [PROD_W-1:0] ix2_00, iy2_00, ix2_01, iy2_01, ix2_02, iy2_02;
    wire [PROD_W-1:0] ix2_10, iy2_10, ix2_11, iy2_11, ix2_12, iy2_12;
    wire [PROD_W-1:0] ix2_20, iy2_20, ix2_21, iy2_21, ix2_22, iy2_22;
    wire signed [PROD_W-1:0] ixy_00, ixy_01, ixy_02, ixy_10, ixy_11, ixy_12, ixy_20, ixy_21, ixy_22;

    harris_grad_products #(.GRAD_W(GRAD_W), .PROD_W(PROD_W)) u_prod00 (.gx(gx00), .gy(gy00), .ix2(ix2_00), .iy2(iy2_00), .ixy(ixy_00));
    harris_grad_products #(.GRAD_W(GRAD_W), .PROD_W(PROD_W)) u_prod01 (.gx(gx01), .gy(gy01), .ix2(ix2_01), .iy2(iy2_01), .ixy(ixy_01));
    harris_grad_products #(.GRAD_W(GRAD_W), .PROD_W(PROD_W)) u_prod02 (.gx(gx02), .gy(gy02), .ix2(ix2_02), .iy2(iy2_02), .ixy(ixy_02));
    harris_grad_products #(.GRAD_W(GRAD_W), .PROD_W(PROD_W)) u_prod10 (.gx(gx10), .gy(gy10), .ix2(ix2_10), .iy2(iy2_10), .ixy(ixy_10));
    harris_grad_products #(.GRAD_W(GRAD_W), .PROD_W(PROD_W)) u_prod11 (.gx(gx11), .gy(gy11), .ix2(ix2_11), .iy2(iy2_11), .ixy(ixy_11));
    harris_grad_products #(.GRAD_W(GRAD_W), .PROD_W(PROD_W)) u_prod12 (.gx(gx12), .gy(gy12), .ix2(ix2_12), .iy2(iy2_12), .ixy(ixy_12));
    harris_grad_products #(.GRAD_W(GRAD_W), .PROD_W(PROD_W)) u_prod20 (.gx(gx20), .gy(gy20), .ix2(ix2_20), .iy2(iy2_20), .ixy(ixy_20));
    harris_grad_products #(.GRAD_W(GRAD_W), .PROD_W(PROD_W)) u_prod21 (.gx(gx21), .gy(gy21), .ix2(ix2_21), .iy2(iy2_21), .ixy(ixy_21));
    harris_grad_products #(.GRAD_W(GRAD_W), .PROD_W(PROD_W)) u_prod22 (.gx(gx22), .gy(gy22), .ix2(ix2_22), .iy2(iy2_22), .ixy(ixy_22));

    wire [SMOOTH_W-1:0] s_ix2, s_iy2;
    wire signed [SMOOTH_W-1:0] s_ixy;

    harris_gaussian3x3 #(.IN_W(PROD_W), .OUT_W(SMOOTH_W), .SIGNED_IN(0)) u_gix2 (
        .p00(ix2_00), .p01(ix2_01), .p02(ix2_02), .p10(ix2_10), .p11(ix2_11), .p12(ix2_12), .p20(ix2_20), .p21(ix2_21), .p22(ix2_22),
        .out(s_ix2)
    );

    harris_gaussian3x3 #(.IN_W(PROD_W), .OUT_W(SMOOTH_W), .SIGNED_IN(0)) u_giy2 (
        .p00(iy2_00), .p01(iy2_01), .p02(iy2_02), .p10(iy2_10), .p11(iy2_11), .p12(iy2_12), .p20(iy2_20), .p21(iy2_21), .p22(iy2_22),
        .out(s_iy2)
    );

    harris_gaussian3x3 #(.IN_W(PROD_W), .OUT_W(SMOOTH_W), .SIGNED_IN(1)) u_gixy (
        .p00(ixy_00), .p01(ixy_01), .p02(ixy_02), .p10(ixy_10), .p11(ixy_11), .p12(ixy_12), .p20(ixy_20), .p21(ixy_21), .p22(ixy_22),
        .out(s_ixy)
    );

    wire signed [RESP_W-1:0] response;
    harris_response #(
        .IN_W(SMOOTH_W),
        .RESP_W(RESP_W),
        .K_W(K_W)
    ) u_response (
        .ix2(s_ix2),
        .iy2(s_iy2),
        .ixy(s_ixy),
        .k_param(k_param),
        .response(response)
    );

    wire corner_comb;
    harris_threshold #(.RESP_W(RESP_W)) u_thresh (
        .response(response),
        .threshold(threshold),
        .is_corner(corner_comb)
    );

    wire interior = (cur_x >= 2) && (cur_x < IMG_WIDTH-2) && (cur_y >= 2) && (cur_y < IMG_HEIGHT-2);

    always @(posedge clk) begin
        if (rst) begin
            in_count <= 0;
            out_count <= 0;
            streaming_done <= 1'b0;
            valid_r <= 1'b0;
            corner_r <= 1'b0;
        end else begin
            valid_r <= 1'b0;
            corner_r <= 1'b0;

            if (valid_in && !streaming_done) begin
                img[in_count] <= pixel_in;
                if (in_count == N-1)
                    streaming_done <= 1'b1;
                in_count <= in_count + 1'b1;
            end

            if (streaming_done && out_count < N) begin
                valid_r <= 1'b1;
                corner_r <= interior ? corner_comb : 1'b0;
                out_count <= out_count + 1'b1;
            end
        end
    end

endmodule