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

    localparam ACC_W = PIXEL_W + 8;
    localparam DIFF_W = PIXEL_W + GAIN_W + 4;

    reg [PIXEL_W-1:0] line0 [0:IMG_WIDTH-1];
    reg [PIXEL_W-1:0] line1 [0:IMG_WIDTH-1];

    reg [31:0] x;
    reg [31:0] y;

    reg [PIXEL_W-1:0] up_left, up_mid, up_right;
    reg [PIXEL_W-1:0] mid_left, mid_mid, mid_right;
    reg [PIXEL_W-1:0] dn_left, dn_mid, dn_right;

    reg [PIXEL_W-1:0] prev0;
    reg [PIXEL_W-1:0] prev1;

    wire [ACC_W-1:0] blur_sum;
    wire [PIXEL_W-1:0] blur_pixel;
    wire signed [DIFF_W-1:0] high_freq;
    wire signed [DIFF_W+GAIN_W-1:0] scaled_high;
    wire signed [DIFF_W+GAIN_W:0] recon;
    wire [PIXEL_W-1:0] sat_pixel;

    reg [PIXEL_W-1:0] pixel_out_r;
    reg valid_out_r;

    integer i;

    gaussian3x3_sum #(
        .PIXEL_W(PIXEL_W),
        .ACC_W(ACC_W)
    ) u_gaussian3x3_sum (
        .p00(up_left),
        .p01(up_mid),
        .p02(up_right),
        .p10(mid_left),
        .p11(mid_mid),
        .p12(mid_right),
        .p20(dn_left),
        .p21(dn_mid),
        .p22(dn_right),
        .sum(blur_sum)
    );

    gaussian3x3_norm #(
        .PIXEL_W(PIXEL_W),
        .ACC_W(ACC_W)
    ) u_gaussian3x3_norm (
        .sum(blur_sum),
        .blur(blur_pixel)
    );

    pixel_difference #(
        .PIXEL_W(PIXEL_W),
        .DIFF_W(DIFF_W)
    ) u_pixel_difference (
        .orig(pixel_in),
        .blur(blur_pixel),
        .diff(high_freq)
    );

    gain_scale #(
        .GAIN_W(GAIN_W),
        .DIFF_W(DIFF_W)
    ) u_gain_scale (
        .diff(high_freq),
        .gain(gain),
        .scaled(scaled_high)
    );

    reconstruct_pixel #(
        .PIXEL_W(PIXEL_W),
        .IN_W(DIFF_W+GAIN_W)
    ) u_reconstruct_pixel (
        .orig(pixel_in),
        .scaled(scaled_high),
        .recon(recon)
    );

    saturate_pixel #(
        .PIXEL_W(PIXEL_W),
        .IN_W(DIFF_W+GAIN_W+1)
    ) u_saturate_pixel (
        .value(recon),
        .pixel(sat_pixel)
    );

    assign pixel_out = pixel_out_r;
    assign valid_out = valid_out_r;

    always @(*) begin
        up_left   = {PIXEL_W{1'b0}};
        up_mid    = {PIXEL_W{1'b0}};
        up_right  = {PIXEL_W{1'b0}};
        mid_left  = {PIXEL_W{1'b0}};
        mid_mid   = {PIXEL_W{1'b0}};
        mid_right = {PIXEL_W{1'b0}};
        dn_left   = {PIXEL_W{1'b0}};
        dn_mid    = pixel_in;
        dn_right  = {PIXEL_W{1'b0}};

        if (y > 1) begin
            if (x > 0) up_left = line0[x-1];
            up_mid = line0[x];
            if (x < IMG_WIDTH-1) up_right = line0[x+1];
        end

        if (y > 0) begin
            if (x > 0) mid_left = line1[x-1];
            mid_mid = line1[x];
            if (x < IMG_WIDTH-1) mid_right = line1[x+1];
        end

        if (x > 0) dn_left = prev1;
    end

    always @(posedge clk) begin
        if (rst) begin
            x <= 0;
            y <= 0;
            prev0 <= 0;
            prev1 <= 0;
            pixel_out_r <= 0;
            valid_out_r <= 0;
            for (i = 0; i < IMG_WIDTH; i = i + 1) begin
                line0[i] <= 0;
                line1[i] <= 0;
            end
        end else begin
            valid_out_r <= valid_in;
            if (valid_in) begin
                pixel_out_r <= sat_pixel;

                line0[x] <= line1[x];
                line1[x] <= pixel_in;
                prev0 <= line1[x];
                prev1 <= pixel_in;

                if (x == IMG_WIDTH-1) begin
                    x <= 0;
                    prev0 <= 0;
                    prev1 <= 0;
                    if (y == IMG_HEIGHT-1)
                        y <= 0;
                    else
                        y <= y + 1;
                end else begin
                    x <= x + 1;
                end
            end
        end
    end

endmodule