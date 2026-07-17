`timescale 1ns/1ps

module unsharp_mask #(
    parameter IMG_WIDTH = 256,
    parameter IMG_HEIGHT = 256,
    parameter PIXEL_W = 8,
    parameter GAIN_W = 8
) (
    input clk,
    input rst,
    input [PIXEL_W-1:0] pixel_in,
    input valid_in,
    input [GAIN_W-1:0] gain,
    output [PIXEL_W-1:0] pixel_out,
    output valid_out
);

    localparam SUM_W = PIXEL_W + 6;
    localparam DIFF_W = PIXEL_W + 2;
    localparam PROD_W = DIFF_W + GAIN_W + 1;

    reg [PIXEL_W-1:0] line0 [0:IMG_WIDTH-1];
    reg [PIXEL_W-1:0] line1 [0:IMG_WIDTH-1];

    reg [PIXEL_W-1:0] top_left, top_mid;
    reg [PIXEL_W-1:0] mid_left, mid_mid;
    reg [PIXEL_W-1:0] bot_left, bot_mid;

    reg [PIXEL_W-1:0] win00, win01, win02;
    reg [PIXEL_W-1:0] win10, win11, win12;
    reg [PIXEL_W-1:0] win20, win21, win22;

    reg [PIXEL_W-1:0] orig_r;
    reg [GAIN_W-1:0] gain_r;
    reg valid_r;

    reg [PIXEL_W-1:0] out_r;
    reg out_valid_r;

    integer col;
    integer row;
    integer i;

    wire [PIXEL_W-1:0] blur_w;
    wire signed [DIFF_W-1:0] diff_w;
    wire signed [PROD_W-1:0] scaled_w;
    wire [PIXEL_W-1:0] recon_w;

    gaussian3x3_blur #(
        .PIXEL_W(PIXEL_W),
        .SUM_W(SUM_W)
    ) u_blur (
        .p00(win00), .p01(win01), .p02(win02),
        .p10(win10), .p11(win11), .p12(win12),
        .p20(win20), .p21(win21), .p22(win22),
        .blurred(blur_w)
    );

    high_frequency #(
        .PIXEL_W(PIXEL_W),
        .DIFF_W(DIFF_W)
    ) u_diff (
        .original(orig_r),
        .blurred(blur_w),
        .diff(diff_w)
    );

    gain_scale #(
        .DIFF_W(DIFF_W),
        .GAIN_W(GAIN_W),
        .PROD_W(PROD_W)
    ) u_gain (
        .diff(diff_w),
        .gain(gain_r),
        .scaled(scaled_w)
    );

    sharpen_reconstruct #(
        .PIXEL_W(PIXEL_W),
        .PROD_W(PROD_W)
    ) u_reconstruct (
        .original(orig_r),
        .scaled(scaled_w),
        .pixel_out(recon_w)
    );

    assign pixel_out = out_r;
    assign valid_out = out_valid_r;

    always @(posedge clk) begin
        if (rst) begin
            col <= 0;
            row <= 0;
            top_left <= 0;
            top_mid <= 0;
            mid_left <= 0;
            mid_mid <= 0;
            bot_left <= 0;
            bot_mid <= 0;
            win00 <= 0;
            win01 <= 0;
            win02 <= 0;
            win10 <= 0;
            win11 <= 0;
            win12 <= 0;
            win20 <= 0;
            win21 <= 0;
            win22 <= 0;
            orig_r <= 0;
            gain_r <= 0;
            valid_r <= 0;
            out_r <= 0;
            out_valid_r <= 0;
            for (i = 0; i < IMG_WIDTH; i = i + 1) begin
                line0[i] <= 0;
                line1[i] <= 0;
            end
        end else begin
            out_r <= recon_w;
            out_valid_r <= valid_r;

            valid_r <= valid_in;
            gain_r <= gain;
            orig_r <= pixel_in;

            if (valid_in) begin
                win00 <= (row < 2 || col < 2) ? {PIXEL_W{1'b0}} : top_left;
                win01 <= (row < 2 || col < 1) ? {PIXEL_W{1'b0}} : top_mid;
                win02 <= (row < 2) ? {PIXEL_W{1'b0}} : line1[col];

                win10 <= (row < 1 || col < 2) ? {PIXEL_W{1'b0}} : mid_left;
                win11 <= (row < 1 || col < 1) ? {PIXEL_W{1'b0}} : mid_mid;
                win12 <= (row < 1) ? {PIXEL_W{1'b0}} : line0[col];

                win20 <= (col < 2) ? {PIXEL_W{1'b0}} : bot_left;
                win21 <= (col < 1) ? {PIXEL_W{1'b0}} : bot_mid;
                win22 <= pixel_in;

                top_left <= top_mid;
                top_mid <= (row < 2) ? {PIXEL_W{1'b0}} : line1[col];

                mid_left <= mid_mid;
                mid_mid <= (row < 1) ? {PIXEL_W{1'b0}} : line0[col];

                bot_left <= bot_mid;
                bot_mid <= pixel_in;

                line1[col] <= line0[col];
                line0[col] <= pixel_in;

                if (col == IMG_WIDTH-1) begin
                    col <= 0;
                    if (row == IMG_HEIGHT-1)
                        row <= 0;
                    else
                        row <= row + 1;

                    top_left <= 0;
                    top_mid <= 0;
                    mid_left <= 0;
                    mid_mid <= 0;
                    bot_left <= 0;
                    bot_mid <= 0;
                end else begin
                    col <= col + 1;
                end
            end
        end
    end

endmodule