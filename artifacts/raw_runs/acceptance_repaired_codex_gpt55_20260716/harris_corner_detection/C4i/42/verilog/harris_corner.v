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
    localparam LATENCY = 4;

    reg [PIXEL_W-1:0] pix_line0 [0:IMG_WIDTH-1];
    reg [PIXEL_W-1:0] pix_line1 [0:IMG_WIDTH-1];

    reg signed [PROD_W-1:0] ix2_line0 [0:IMG_WIDTH-1];
    reg signed [PROD_W-1:0] ix2_line1 [0:IMG_WIDTH-1];
    reg signed [PROD_W-1:0] iy2_line0 [0:IMG_WIDTH-1];
    reg signed [PROD_W-1:0] iy2_line1 [0:IMG_WIDTH-1];
    reg signed [PROD_W-1:0] ixy_line0 [0:IMG_WIDTH-1];
    reg signed [PROD_W-1:0] ixy_line1 [0:IMG_WIDTH-1];

    reg [PIXEL_W-1:0] p00, p01, p02;
    reg [PIXEL_W-1:0] p10, p11, p12;
    reg [PIXEL_W-1:0] p20, p21, p22;

    reg signed [PROD_W-1:0] ix2_00, ix2_01, ix2_02;
    reg signed [PROD_W-1:0] ix2_10, ix2_11, ix2_12;
    reg signed [PROD_W-1:0] ix2_20, ix2_21, ix2_22;

    reg signed [PROD_W-1:0] iy2_00, iy2_01, iy2_02;
    reg signed [PROD_W-1:0] iy2_10, iy2_11, iy2_12;
    reg signed [PROD_W-1:0] iy2_20, iy2_21, iy2_22;

    reg signed [PROD_W-1:0] ixy_00, ixy_01, ixy_02;
    reg signed [PROD_W-1:0] ixy_10, ixy_11, ixy_12;
    reg signed [PROD_W-1:0] ixy_20, ixy_21, ixy_22;

    reg [15:0] col;
    reg [15:0] row;

    reg signed [GRAD_W-1:0] gx_r, gy_r;
    reg signed [PROD_W-1:0] ix2_r, iy2_r, ixy_r;
    reg signed [SMOOTH_W-1:0] sx2_r, sy2_r, sxy_r;
    reg signed [RESP_W-1:0] resp_r;
    reg corner_r;

    reg [LATENCY-1:0] valid_pipe;
    reg [LATENCY-1:0] border_pipe;

    wire signed [GRAD_W-1:0] gx_w;
    wire signed [GRAD_W-1:0] gy_w;
    wire signed [PROD_W-1:0] ix2_w;
    wire signed [PROD_W-1:0] iy2_w;
    wire signed [PROD_W-1:0] ixy_w;
    wire signed [SMOOTH_W-1:0] sx2_w;
    wire signed [SMOOTH_W-1:0] sy2_w;
    wire signed [SMOOTH_W-1:0] sxy_w;
    wire signed [RESP_W-1:0] resp_w;
    wire corner_w;

    wire grad_valid_now = (row >= 2) && (col >= 2);
    wire border_now = (row < 4) || (col < 4) || (row >= IMG_HEIGHT) || (col >= IMG_WIDTH);

    sobel3x3 #(
        .PIXEL_W(PIXEL_W),
        .GRAD_W(GRAD_W)
    ) u_sobel (
        .p00(p00), .p01(p01), .p02(p02),
        .p10(p10), .p11(p11), .p12(p12),
        .p20(p20), .p21(p21), .p22(p22),
        .gx(gx_w),
        .gy(gy_w)
    );

    gradient_products #(
        .GRAD_W(GRAD_W),
        .PROD_W(PROD_W)
    ) u_products (
        .gx(gx_r),
        .gy(gy_r),
        .ix2(ix2_w),
        .iy2(iy2_w),
        .ixy(ixy_w)
    );

    gaussian3x3 #(
        .IN_W(PROD_W),
        .OUT_W(SMOOTH_W)
    ) u_gaussian_x2 (
        .v00(ix2_00), .v01(ix2_01), .v02(ix2_02),
        .v10(ix2_10), .v11(ix2_11), .v12(ix2_12),
        .v20(ix2_20), .v21(ix2_21), .v22(ix2_22),
        .sum(sx2_w)
    );

    gaussian3x3 #(
        .IN_W(PROD_W),
        .OUT_W(SMOOTH_W)
    ) u_gaussian_y2 (
        .v00(iy2_00), .v01(iy2_01), .v02(iy2_02),
        .v10(iy2_10), .v11(iy2_11), .v12(iy2_12),
        .v20(iy2_20), .v21(iy2_21), .v22(iy2_22),
        .sum(sy2_w)
    );

    gaussian3x3 #(
        .IN_W(PROD_W),
        .OUT_W(SMOOTH_W)
    ) u_gaussian_xy (
        .v00(ixy_00), .v01(ixy_01), .v02(ixy_02),
        .v10(ixy_10), .v11(ixy_11), .v12(ixy_12),
        .v20(ixy_20), .v21(ixy_21), .v22(ixy_22),
        .sum(sxy_w)
    );

    harris_response #(
        .IN_W(SMOOTH_W),
        .RESP_W(RESP_W),
        .K_W(K_W)
    ) u_response (
        .ix2(sx2_r),
        .iy2(sy2_r),
        .ixy(sxy_r),
        .k_param(k_param),
        .response(resp_w)
    );

    threshold_compare #(
        .RESP_W(RESP_W)
    ) u_threshold (
        .response(resp_r),
        .threshold(threshold),
        .is_corner(corner_w)
    );

    assign valid_out = valid_pipe[LATENCY-1];
    assign is_corner = valid_out ? (border_pipe[LATENCY-1] ? 1'b0 : corner_r) : 1'b0;

    integer i;
    always @(posedge clk) begin
        if (rst) begin
            col <= 0;
            row <= 0;
            valid_pipe <= 0;
            border_pipe <= 0;
            gx_r <= 0;
            gy_r <= 0;
            ix2_r <= 0;
            iy2_r <= 0;
            ixy_r <= 0;
            sx2_r <= 0;
            sy2_r <= 0;
            sxy_r <= 0;
            resp_r <= 0;
            corner_r <= 0;

            p00 <= 0; p01 <= 0; p02 <= 0;
            p10 <= 0; p11 <= 0; p12 <= 0;
            p20 <= 0; p21 <= 0; p22 <= 0;

            ix2_00 <= 0; ix2_01 <= 0; ix2_02 <= 0;
            ix2_10 <= 0; ix2_11 <= 0; ix2_12 <= 0;
            ix2_20 <= 0; ix2_21 <= 0; ix2_22 <= 0;

            iy2_00 <= 0; iy2_01 <= 0; iy2_02 <= 0;
            iy2_10 <= 0; iy2_11 <= 0; iy2_12 <= 0;
            iy2_20 <= 0; iy2_21 <= 0; iy2_22 <= 0;

            ixy_00 <= 0; ixy_01 <= 0; ixy_02 <= 0;
            ixy_10 <= 0; ixy_11 <= 0; ixy_12 <= 0;
            ixy_20 <= 0; ixy_21 <= 0; ixy_22 <= 0;

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
            valid_pipe <= {valid_pipe[LATENCY-2:0], valid_in};
            border_pipe <= {border_pipe[LATENCY-2:0], border_now};

            gx_r <= grad_valid_now ? gx_w : {GRAD_W{1'b0}};
            gy_r <= grad_valid_now ? gy_w : {GRAD_W{1'b0}};
            ix2_r <= ix2_w;
            iy2_r <= iy2_w;
            ixy_r <= ixy_w;
            sx2_r <= sx2_w;
            sy2_r <= sy2_w;
            sxy_r <= sxy_w;
            resp_r <= resp_w;
            corner_r <= corner_w;

            if (valid_in) begin
                p00 <= p01;
                p01 <= p02;
                p02 <= pix_line1[col];
                p10 <= p11;
                p11 <= p12;
                p12 <= pix_line0[col];
                p20 <= p21;
                p21 <= p22;
                p22 <= pixel_in;

                pix_line1[col] <= pix_line0[col];
                pix_line0[col] <= pixel_in;

                ix2_00 <= ix2_01;
                ix2_01 <= ix2_02;
                ix2_02 <= ix2_line1[col];
                ix2_10 <= ix2_11;
                ix2_11 <= ix2_12;
                ix2_12 <= ix2_line0[col];
                ix2_20 <= ix2_21;
                ix2_21 <= ix2_22;
                ix2_22 <= ix2_r;

                iy2_00 <= iy2_01;
                iy2_01 <= iy2_02;
                iy2_02 <= iy2_line1[col];
                iy2_10 <= iy2_11;
                iy2_11 <= iy2_12;
                iy2_12 <= iy2_line0[col];
                iy2_20 <= iy2_21;
                iy2_21 <= iy2_22;
                iy2_22 <= iy2_r;

                ixy_00 <= ixy_01;
                ixy_01 <= ixy_02;
                ixy_02 <= ixy_line1[col];
                ixy_10 <= ixy_11;
                ixy_11 <= ixy_12;
                ixy_12 <= ixy_line0[col];
                ixy_20 <= ixy_21;
                ixy_21 <= ixy_22;
                ixy_22 <= ixy_r;

                ix2_line1[col] <= ix2_line0[col];
                ix2_line0[col] <= ix2_r;
                iy2_line1[col] <= iy2_line0[col];
                iy2_line0[col] <= iy2_r;
                ixy_line1[col] <= ixy_line0[col];
                ixy_line0[col] <= ixy_r;

                if (col == IMG_WIDTH-1) begin
                    col <= 0;
                    if (row == IMG_HEIGHT-1)
                        row <= row;
                    else
                        row <= row + 1'b1;
                end else begin
                    col <= col + 1'b1;
                end
            end
        end
    end

endmodule