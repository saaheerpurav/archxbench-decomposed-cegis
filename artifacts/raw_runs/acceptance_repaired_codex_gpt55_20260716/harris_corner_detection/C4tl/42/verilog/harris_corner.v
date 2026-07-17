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
    localparam PROD_W = 2 * GRAD_W;
    localparam SMOOTH_W = PROD_W + 8;
    localparam CALC_W = 64;

    reg [PIXEL_W-1:0] image [0:N-1];

    reg [31:0] in_count;
    reg [31:0] out_count;
    reg emitting;

    reg is_corner_r;
    reg valid_out_r;

    assign is_corner = is_corner_r;
    assign valid_out = valid_out_r;

    integer dx;
    integer dy;
    integer rr;
    integer cc;
    integer tap_index;

    reg signed [31:0] base_row;
    reg signed [31:0] base_col;

    reg [PIXEL_W-1:0] p00 [0:8];
    reg [PIXEL_W-1:0] p01 [0:8];
    reg [PIXEL_W-1:0] p02 [0:8];
    reg [PIXEL_W-1:0] p10 [0:8];
    reg [PIXEL_W-1:0] p11 [0:8];
    reg [PIXEL_W-1:0] p12 [0:8];
    reg [PIXEL_W-1:0] p20 [0:8];
    reg [PIXEL_W-1:0] p21 [0:8];
    reg [PIXEL_W-1:0] p22 [0:8];

    wire signed [GRAD_W-1:0] gx [0:8];
    wire signed [GRAD_W-1:0] gy [0:8];

    wire [PROD_W-1:0] ix2 [0:8];
    wire [PROD_W-1:0] iy2 [0:8];
    wire signed [PROD_W-1:0] ixy [0:8];

    wire [SMOOTH_W-1:0] s_ix2;
    wire [SMOOTH_W-1:0] s_iy2;
    wire signed [SMOOTH_W-1:0] s_ixy;

    wire signed [RESP_W-1:0] response_value;
    wire corner_value;

    function [PIXEL_W-1:0] get_pixel;
        input signed [31:0] row;
        input signed [31:0] col;
        integer idx;
        begin
            if (row < 0 || row >= IMG_HEIGHT || col < 0 || col >= IMG_WIDTH) begin
                get_pixel = {PIXEL_W{1'b0}};
            end else begin
                idx = row * IMG_WIDTH + col;
                get_pixel = image[idx];
            end
        end
    endfunction

    always @* begin
        base_row = out_count / IMG_WIDTH;
        base_col = out_count % IMG_WIDTH;

        for (tap_index = 0; tap_index < 9; tap_index = tap_index + 1) begin
            dy = (tap_index / 3) - 1;
            dx = (tap_index % 3) - 1;
            rr = base_row + dy;
            cc = base_col + dx;

            p00[tap_index] = get_pixel(rr - 1, cc - 1);
            p01[tap_index] = get_pixel(rr - 1, cc    );
            p02[tap_index] = get_pixel(rr - 1, cc + 1);
            p10[tap_index] = get_pixel(rr,     cc - 1);
            p11[tap_index] = get_pixel(rr,     cc    );
            p12[tap_index] = get_pixel(rr,     cc + 1);
            p20[tap_index] = get_pixel(rr + 1, cc - 1);
            p21[tap_index] = get_pixel(rr + 1, cc    );
            p22[tap_index] = get_pixel(rr + 1, cc + 1);
        end
    end

    genvar gi;
    generate
        for (gi = 0; gi < 9; gi = gi + 1) begin : GEN_STENCIL
            harris_sobel_3x3 #(
                .PIXEL_W(PIXEL_W),
                .GRAD_W(GRAD_W)
            ) sobel_inst (
                .p00(p00[gi]), .p01(p01[gi]), .p02(p02[gi]),
                .p10(p10[gi]), .p11(p11[gi]), .p12(p12[gi]),
                .p20(p20[gi]), .p21(p21[gi]), .p22(p22[gi]),
                .gx(gx[gi]),
                .gy(gy[gi])
            );

            harris_gradient_products #(
                .GRAD_W(GRAD_W),
                .PROD_W(PROD_W)
            ) prod_inst (
                .gx(gx[gi]),
                .gy(gy[gi]),
                .ix2(ix2[gi]),
                .iy2(iy2[gi]),
                .ixy(ixy[gi])
            );
        end
    endgenerate

    harris_gaussian_3x3 #(
        .PROD_W(PROD_W),
        .OUT_W(SMOOTH_W)
    ) smooth_inst (
        .ix2_00(ix2[0]), .ix2_01(ix2[1]), .ix2_02(ix2[2]),
        .ix2_10(ix2[3]), .ix2_11(ix2[4]), .ix2_12(ix2[5]),
        .ix2_20(ix2[6]), .ix2_21(ix2[7]), .ix2_22(ix2[8]),
        .iy2_00(iy2[0]), .iy2_01(iy2[1]), .iy2_02(iy2[2]),
        .iy2_10(iy2[3]), .iy2_11(iy2[4]), .iy2_12(iy2[5]),
        .iy2_20(iy2[6]), .iy2_21(iy2[7]), .iy2_22(iy2[8]),
        .ixy_00(ixy[0]), .ixy_01(ixy[1]), .ixy_02(ixy[2]),
        .ixy_10(ixy[3]), .ixy_11(ixy[4]), .ixy_12(ixy[5]),
        .ixy_20(ixy[6]), .ixy_21(ixy[7]), .ixy_22(ixy[8]),
        .smooth_ix2(s_ix2),
        .smooth_iy2(s_iy2),
        .smooth_ixy(s_ixy)
    );

    harris_response #(
        .IN_W(SMOOTH_W),
        .RESP_W(RESP_W),
        .K_W(K_W),
        .CALC_W(CALC_W)
    ) response_inst (
        .ix2(s_ix2),
        .iy2(s_iy2),
        .ixy(s_ixy),
        .k_param(k_param),
        .response(response_value)
    );

    harris_threshold #(
        .RESP_W(RESP_W)
    ) threshold_inst (
        .response(response_value),
        .threshold(threshold),
        .is_corner(corner_value)
    );

    always @(posedge clk) begin
        if (rst) begin
            in_count <= 0;
            out_count <= 0;
            emitting <= 1'b0;
            is_corner_r <= 1'b0;
            valid_out_r <= 1'b0;
        end else begin
            valid_out_r <= 1'b0;

            if (valid_in && !emitting && in_count < N) begin
                image[in_count] <= pixel_in;
                in_count <= in_count + 1;
                if (in_count == N - 1) begin
                    emitting <= 1'b1;
                    out_count <= 0;
                end
            end

            if (emitting) begin
                valid_out_r <= 1'b1;
                is_corner_r <= corner_value;
                if (out_count == N - 1) begin
                    emitting <= 1'b0;
                    out_count <= out_count;
                end else begin
                    out_count <= out_count + 1;
                end
            end
        end
    end

endmodule