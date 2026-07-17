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

    localparam PROD_W = (2*GRAD_W);
    localparam SMOOTH_W = PROD_W + 4;

    reg [PIXEL_W-1:0] pix_line0 [0:IMG_WIDTH-1];
    reg [PIXEL_W-1:0] pix_line1 [0:IMG_WIDTH-1];

    reg [PIXEL_W-1:0] p00, p01, p02;
    reg [PIXEL_W-1:0] p10, p11, p12;
    reg [PIXEL_W-1:0] p20, p21, p22;

    reg [PROD_W-1:0] ix2_line0 [0:IMG_WIDTH-1];
    reg [PROD_W-1:0] ix2_line1 [0:IMG_WIDTH-1];
    reg [PROD_W-1:0] iy2_line0 [0:IMG_WIDTH-1];
    reg [PROD_W-1:0] iy2_line1 [0:IMG_WIDTH-1];
    reg signed [PROD_W-1:0] ixy_line0 [0:IMG_WIDTH-1];
    reg signed [PROD_W-1:0] ixy_line1 [0:IMG_WIDTH-1];

    reg [PROD_W-1:0] ix200, ix201, ix202;
    reg [PROD_W-1:0] ix210, ix211, ix212;
    reg [PROD_W-1:0] ix220, ix221, ix222;

    reg [PROD_W-1:0] iy200, iy201, iy202;
    reg [PROD_W-1:0] iy210, iy211, iy212;
    reg [PROD_W-1:0] iy220, iy221, iy222;

    reg signed [PROD_W-1:0] ixy00, ixy01, ixy02;
    reg signed [PROD_W-1:0] ixy10, ixy11, ixy12;
    reg signed [PROD_W-1:0] ixy20, ixy21, ixy22;

    reg [$clog2(IMG_WIDTH)-1:0] x_pos;
    reg [$clog2(IMG_HEIGHT)-1:0] y_pos;

    wire signed [GRAD_W-1:0] gx_w;
    wire signed [GRAD_W-1:0] gy_w;

    wire [PROD_W-1:0] ix2_w;
    wire [PROD_W-1:0] iy2_w;
    wire signed [PROD_W-1:0] ixy_w;

    wire [SMOOTH_W-1:0] sx2_w;
    wire [SMOOTH_W-1:0] sy2_w;
    wire signed [SMOOTH_W-1:0] sxy_w;

    wire signed [RESP_W-1:0] response_w;
    wire corner_w;

    reg signed [GRAD_W-1:0] gx_r, gy_r;
    reg [PROD_W-1:0] ix2_r, iy2_r;
    reg signed [PROD_W-1:0] ixy_r;
    reg [SMOOTH_W-1:0] sx2_r, sy2_r;
    reg signed [SMOOTH_W-1:0] sxy_r;
    reg signed [RESP_W-1:0] response_r;
    reg corner_r;

    reg [6:0] valid_pipe;

    integer i;

    harris_sobel3x3 #(
        .PIXEL_W(PIXEL_W),
        .GRAD_W(GRAD_W)
    ) u_sobel (
        .p00(p00), .p01(p01), .p02(p02),
        .p10(p10), .p11(p11), .p12(p12),
        .p20(p20), .p21(p21), .p22(p22),
        .gx(gx_w),
        .gy(gy_w)
    );

    harris_gradient_products #(
        .GRAD_W(GRAD_W),
        .PROD_W(PROD_W)
    ) u_products (
        .gx(gx_r),
        .gy(gy_r),
        .ix2(ix2_w),
        .iy2(iy2_w),
        .ixy(ixy_w)
    );

    harris_gaussian3x3 #(
        .IN_W(PROD_W),
        .OUT_W(SMOOTH_W)
    ) u_gaussian (
        .ix200(ix200), .ix201(ix201), .ix202(ix202),
        .ix210(ix210), .ix211(ix211), .ix212(ix212),
        .ix220(ix220), .ix221(ix221), .ix222(ix222),
        .iy200(iy200), .iy201(iy201), .iy202(iy202),
        .iy210(iy210), .iy211(iy211), .iy212(iy212),
        .iy220(iy220), .iy221(iy221), .iy222(iy222),
        .ixy00(ixy00), .ixy01(ixy01), .ixy02(ixy02),
        .ixy10(ixy10), .ixy11(ixy11), .ixy12(ixy12),
        .ixy20(ixy20), .ixy21(ixy21), .ixy22(ixy22),
        .sx2(sx2_w),
        .sy2(sy2_w),
        .sxy(sxy_w)
    );

    harris_response_calc #(
        .IN_W(SMOOTH_W),
        .RESP_W(RESP_W),
        .K_W(K_W)
    ) u_response (
        .sx2(sx2_r),
        .sy2(sy2_r),
        .sxy(sxy_r),
        .k_param(k_param),
        .response(response_w)
    );

    harris_threshold #(
        .RESP_W(RESP_W)
    ) u_threshold (
        .response(response_r),
        .threshold(threshold),
        .is_corner(corner_w)
    );

    always @(posedge clk) begin
        if (rst) begin
            x_pos <= 0;
            y_pos <= 0;
            p00 <= 0; p01 <= 0; p02 <= 0;
            p10 <= 0; p11 <= 0; p12 <= 0;
            p20 <= 0; p21 <= 0; p22 <= 0;
            ix200 <= 0; ix201 <= 0; ix202 <= 0;
            ix210 <= 0; ix211 <= 0; ix212 <= 0;
            ix220 <= 0; ix221 <= 0; ix222 <= 0;
            iy200 <= 0; iy201 <= 0; iy202 <= 0;
            iy210 <= 0; iy211 <= 0; iy212 <= 0;
            iy220 <= 0; iy221 <= 0; iy222 <= 0;
            ixy00 <= 0; ixy01 <= 0; ixy02 <= 0;
            ixy10 <= 0; ixy11 <= 0; ixy12 <= 0;
            ixy20 <= 0; ixy21 <= 0; ixy22 <= 0;
            gx_r <= 0;
            gy_r <= 0;
            ix2_r <= 0;
            iy2_r <= 0;
            ixy_r <= 0;
            sx2_r <= 0;
            sy2_r <= 0;
            sxy_r <= 0;
            response_r <= 0;
            corner_r <= 0;
            valid_pipe <= 0;
            for (i = 0; i < IMG_WIDTH; i = i + 1) begin
                pix_line0[i] <= 0;
                pix_line1[i] <= 0;
                ix2_line0[i] <= 0;
                ix2_line1[i] <= 0;
                iy2_line0[i] <= 0;
                iy2_line1[i] <= 0;
                ixy_line0[i] <= 0;
                ixy_line1[i] <= 0;
            end
        end else begin
            valid_pipe <= {valid_pipe[5:0], valid_in};

            gx_r <= gx_w;
            gy_r <= gy_w;
            ix2_r <= ix2_w;
            iy2_r <= iy2_w;
            ixy_r <= ixy_w;
            sx2_r <= sx2_w;
            sy2_r <= sy2_w;
            sxy_r <= sxy_w;
            response_r <= response_w;
            corner_r <= corner_w;

            if (valid_in) begin
                pix_line0[x_pos] <= pixel_in;
                pix_line1[x_pos] <= pix_line0[x_pos];

                ix2_line0[x_pos] <= ix2_r;
                ix2_line1[x_pos] <= ix2_line0[x_pos];
                iy2_line0[x_pos] <= iy2_r;
                iy2_line1[x_pos] <= iy2_line0[x_pos];
                ixy_line0[x_pos] <= ixy_r;
                ixy_line1[x_pos] <= ixy_line0[x_pos];

                if (x_pos == 0) begin
                    p00 <= 0; p01 <= (y_pos > 1) ? pix_line1[x_pos] : 0; p02 <= 0;
                    p10 <= 0; p11 <= (y_pos > 0) ? pix_line0[x_pos] : 0; p12 <= 0;
                    p20 <= 0; p21 <= pixel_in; p22 <= 0;

                    ix200 <= 0; ix201 <= ix2_line1[x_pos]; ix202 <= 0;
                    ix210 <= 0; ix211 <= ix2_line0[x_pos]; ix212 <= 0;
                    ix220 <= 0; ix221 <= ix2_r;          ix222 <= 0;

                    iy200 <= 0; iy201 <= iy2_line1[x_pos]; iy202 <= 0;
                    iy210 <= 0; iy211 <= iy2_line0[x_pos]; iy212 <= 0;
                    iy220 <= 0; iy221 <= iy2_r;          iy222 <= 0;

                    ixy00 <= 0; ixy01 <= ixy_line1[x_pos]; ixy02 <= 0;
                    ixy10 <= 0; ixy11 <= ixy_line0[x_pos]; ixy12 <= 0;
                    ixy20 <= 0; ixy21 <= ixy_r;           ixy22 <= 0;
                end else begin
                    p00 <= p01; p01 <= p02; p02 <= (y_pos > 1) ? pix_line1[x_pos] : 0;
                    p10 <= p11; p11 <= p12; p12 <= (y_pos > 0) ? pix_line0[x_pos] : 0;
                    p20 <= p21; p21 <= p22; p22 <= pixel_in;

                    ix200 <= ix201; ix201 <= ix202; ix202 <= ix2_line1[x_pos];
                    ix210 <= ix211; ix211 <= ix212; ix212 <= ix2_line0[x_pos];
                    ix220 <= ix221; ix221 <= ix222; ix222 <= ix2_r;

                    iy200 <= iy201; iy201 <= iy202; iy202 <= iy2_line1[x_pos];
                    iy210 <= iy211; iy211 <= iy212; iy212 <= iy2_line0[x_pos];
                    iy220 <= iy221; iy221 <= iy222; iy222 <= iy2_r;

                    ixy00 <= ixy01; ixy01 <= ixy02; ixy02 <= ixy_line1[x_pos];
                    ixy10 <= ixy11; ixy11 <= ixy12; ixy12 <= ixy_line0[x_pos];
                    ixy20 <= ixy21; ixy21 <= ixy22; ixy22 <= ixy_r;
                end

                if (x_pos == IMG_WIDTH-1) begin
                    x_pos <= 0;
                    if (y_pos == IMG_HEIGHT-1)
                        y_pos <= 0;
                    else
                        y_pos <= y_pos + 1'b1;
                end else begin
                    x_pos <= x_pos + 1'b1;
                end
            end
        end
    end

    assign is_corner = corner_r;
    assign valid_out = valid_pipe[6];

endmodule