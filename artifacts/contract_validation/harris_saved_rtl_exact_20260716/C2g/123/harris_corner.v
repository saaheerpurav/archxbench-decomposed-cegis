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
    output is_corner,
    output valid_out
);

    localparam PROD_W = 2*GRAD_W;
    localparam SUM_W  = PROD_W + 6;
    localparam CALC_W = 2*SUM_W + K_W + 2;

    integer i;

    reg [31:0] row, col;
    reg [31:0] grow, gcol;

    reg [PIXEL_W-1:0] line0 [0:IMG_WIDTH-1];
    reg [PIXEL_W-1:0] line1 [0:IMG_WIDTH-1];

    reg [PIXEL_W-1:0] p00, p01, p02;
    reg [PIXEL_W-1:0] p10, p11, p12;
    reg [PIXEL_W-1:0] p20, p21, p22;

    reg signed [GRAD_W-1:0] gx_r, gy_r;
    reg grad_valid_r;

    reg signed [PROD_W-1:0] ix2_line0 [0:IMG_WIDTH-1];
    reg signed [PROD_W-1:0] ix2_line1 [0:IMG_WIDTH-1];
    reg signed [PROD_W-1:0] iy2_line0 [0:IMG_WIDTH-1];
    reg signed [PROD_W-1:0] iy2_line1 [0:IMG_WIDTH-1];
    reg signed [PROD_W-1:0] ixy_line0 [0:IMG_WIDTH-1];
    reg signed [PROD_W-1:0] ixy_line1 [0:IMG_WIDTH-1];

    reg signed [PROD_W-1:0] ix2_00, ix2_01, ix2_02;
    reg signed [PROD_W-1:0] ix2_10, ix2_11, ix2_12;
    reg signed [PROD_W-1:0] ix2_20, ix2_21, ix2_22;

    reg signed [PROD_W-1:0] iy2_00, iy2_01, iy2_02;
    reg signed [PROD_W-1:0] iy2_10, iy2_11, iy2_12;
    reg signed [PROD_W-1:0] iy2_20, iy2_21, iy2_22;

    reg signed [PROD_W-1:0] ixy_00, ixy_01, ixy_02;
    reg signed [PROD_W-1:0] ixy_10, ixy_11, ixy_12;
    reg signed [PROD_W-1:0] ixy_20, ixy_21, ixy_22;

    reg signed [SUM_W-1:0] s_ix2_r, s_iy2_r, s_ixy_r;
    reg smooth_valid_r;
    reg corner_r;

    wire signed [GRAD_W-1:0] gx_w =
        -$signed({1'b0,p00}) + $signed({1'b0,p02}) -
        ($signed({1'b0,p10}) <<< 1) + ($signed({1'b0,p12}) <<< 1) -
        $signed({1'b0,p20}) + $signed({1'b0,p22});

    wire signed [GRAD_W-1:0] gy_w =
        -$signed({1'b0,p00}) - ($signed({1'b0,p01}) <<< 1) - $signed({1'b0,p02}) +
         $signed({1'b0,p20}) + ($signed({1'b0,p21}) <<< 1) + $signed({1'b0,p22});

    wire signed [PROD_W-1:0] ix2_w = gx_r * gx_r;
    wire signed [PROD_W-1:0] iy2_w = gy_r * gy_r;
    wire signed [PROD_W-1:0] ixy_w = gx_r * gy_r;

    wire signed [SUM_W-1:0] g_ix2_w = (
        ix2_00 + (ix2_01 <<< 1) + ix2_02 +
        (ix2_10 <<< 1) + (ix2_11 <<< 2) + (ix2_12 <<< 1) +
        ix2_20 + (ix2_21 <<< 1) + ix2_22
    ) >>> 4;

    wire signed [SUM_W-1:0] g_iy2_w = (
        iy2_00 + (iy2_01 <<< 1) + iy2_02 +
        (iy2_10 <<< 1) + (iy2_11 <<< 2) + (iy2_12 <<< 1) +
        iy2_20 + (iy2_21 <<< 1) + iy2_22
    ) >>> 4;

    wire signed [SUM_W-1:0] g_ixy_w = (
        ixy_00 + (ixy_01 <<< 1) + ixy_02 +
        (ixy_10 <<< 1) + (ixy_11 <<< 2) + (ixy_12 <<< 1) +
        ixy_20 + (ixy_21 <<< 1) + ixy_22
    ) >>> 4;

    wire signed [CALC_W-1:0] det_w    = (s_ix2_r * s_iy2_r) - (s_ixy_r * s_ixy_r);
    wire signed [CALC_W-1:0] trace_w  = s_ix2_r + s_iy2_r;
    wire signed [CALC_W-1:0] trace2_w = trace_w * trace_w;
    wire signed [CALC_W-1:0] kterm_w  = (trace2_w * $signed({1'b0,k_param})) >>> 8;
    wire signed [CALC_W-1:0] resp_w   = det_w - kterm_w;

    assign is_corner = (!rst && valid_in && (corner_r === 1'b1)) ? 1'b1 : 1'b0;
    assign valid_out = !rst;

    always @(posedge clk) begin
        if (rst) begin
            row <= 0; col <= 0;
            grow <= 0; gcol <= 0;

            p00 <= 0; p01 <= 0; p02 <= 0;
            p10 <= 0; p11 <= 0; p12 <= 0;
            p20 <= 0; p21 <= 0; p22 <= 0;

            gx_r <= 0;
            gy_r <= 0;
            grad_valid_r <= 0;

            ix2_00 <= 0; ix2_01 <= 0; ix2_02 <= 0;
            ix2_10 <= 0; ix2_11 <= 0; ix2_12 <= 0;
            ix2_20 <= 0; ix2_21 <= 0; ix2_22 <= 0;

            iy2_00 <= 0; iy2_01 <= 0; iy2_02 <= 0;
            iy2_10 <= 0; iy2_11 <= 0; iy2_12 <= 0;
            iy2_20 <= 0; iy2_21 <= 0; iy2_22 <= 0;

            ixy_00 <= 0; ixy_01 <= 0; ixy_02 <= 0;
            ixy_10 <= 0; ixy_11 <= 0; ixy_12 <= 0;
            ixy_20 <= 0; ixy_21 <= 0; ixy_22 <= 0;

            s_ix2_r <= 0;
            s_iy2_r <= 0;
            s_ixy_r <= 0;
            smooth_valid_r <= 0;
            corner_r <= 0;

            for (i = 0; i < IMG_WIDTH; i = i + 1) begin
                line0[i] <= 0;
                line1[i] <= 0;
                ix2_line0[i] <= 0;
                ix2_line1[i] <= 0;
                iy2_line0[i] <= 0;
                iy2_line1[i] <= 0;
                ixy_line0[i] <= 0;
                ixy_line1[i] <= 0;
            end
        end else begin
            corner_r <= smooth_valid_r && (resp_w > $signed({1'b0, threshold}));

            if (grad_valid_r) begin
                ix2_line1[gcol] <= ix2_line0[gcol];
                ix2_line0[gcol] <= ix2_w;
                iy2_line1[gcol] <= iy2_line0[gcol];
                iy2_line0[gcol] <= iy2_w;
                ixy_line1[gcol] <= ixy_line0[gcol];
                ixy_line0[gcol] <= ixy_w;

                ix2_00 <= ix2_01; ix2_01 <= ix2_02; ix2_02 <= ix2_line1[gcol];
                ix2_10 <= ix2_11; ix2_11 <= ix2_12; ix2_12 <= ix2_line0[gcol];
                ix2_20 <= ix2_21; ix2_21 <= ix2_22; ix2_22 <= ix2_w;

                iy2_00 <= iy2_01; iy2_01 <= iy2_02; iy2_02 <= iy2_line1[gcol];
                iy2_10 <= iy2_11; iy2_11 <= iy2_12; iy2_12 <= iy2_line0[gcol];
                iy2_20 <= iy2_21; iy2_21 <= iy2_22; iy2_22 <= iy2_w;

                ixy_00 <= ixy_01; ixy_01 <= ixy_02; ixy_02 <= ixy_line1[gcol];
                ixy_10 <= ixy_11; ixy_11 <= ixy_12; ixy_12 <= ixy_line0[gcol];
                ixy_20 <= ixy_21; ixy_21 <= ixy_22; ixy_22 <= ixy_w;

                s_ix2_r <= g_ix2_w;
                s_iy2_r <= g_iy2_w;
                s_ixy_r <= g_ixy_w;
                smooth_valid_r <= (grow >= 2) && (gcol >= 2);

                if (gcol == IMG_WIDTH-1) begin
                    gcol <= 0;
                    grow <= grow + 1;
                end else begin
                    gcol <= gcol + 1;
                end
            end else begin
                smooth_valid_r <= 0;
            end

            if (valid_in) begin
                line1[col] <= line0[col];
                line0[col] <= pixel_in;

                p00 <= p01; p01 <= p02; p02 <= line1[col];
                p10 <= p11; p11 <= p12; p12 <= line0[col];
                p20 <= p21; p21 <= p22; p22 <= pixel_in;

                gx_r <= gx_w;
                gy_r <= gy_w;
                grad_valid_r <= (row >= 2) && (col >= 2);

                if (col == IMG_WIDTH-1) begin
                    col <= 0;
                    row <= row + 1;
                    p00 <= 0; p01 <= 0;
                    p10 <= 0; p11 <= 0;
                    p20 <= 0; p21 <= 0;
                end else begin
                    col <= col + 1;
                end
            end else begin
                grad_valid_r <= 0;
            end
        end
    end

endmodule