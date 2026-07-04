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

    reg [PIXEL_W-1:0] line1 [0:IMG_WIDTH-1];
    reg [PIXEL_W-1:0] line2 [0:IMG_WIDTH-1];

    reg [PIXEL_W-1:0] cur_l1, cur_l2;
    reg [PIXEL_W-1:0] row1_l1, row1_l2;
    reg [PIXEL_W-1:0] row0_l1, row0_l2;

    reg [PIXEL_W-1:0] w00_r, w01_r, w02_r;
    reg [PIXEL_W-1:0] w10_r, w11_r, w12_r;
    reg [PIXEL_W-1:0] w20_r, w21_r, w22_r;
    reg [PIXEL_W-1:0] orig_r;
    reg [GAIN_W-1:0] gain_r;
    reg valid_r;

    integer x;
    integer y;
    integer i;

    wire [PIXEL_W-1:0] blurred_w;
    wire signed [PIXEL_W:0] high_w;
    wire signed [PIXEL_W+GAIN_W:0] scaled_w;
    wire [PIXEL_W-1:0] result_w;

    gaussian3x3 #(
        .PIXEL_W(PIXEL_W)
    ) u_blur (
        .p00(w00_r), .p01(w01_r), .p02(w02_r),
        .p10(w10_r), .p11(w11_r), .p12(w12_r),
        .p20(w20_r), .p21(w21_r), .p22(w22_r),
        .blurred(blurred_w)
    );

    high_freq_sub #(
        .PIXEL_W(PIXEL_W)
    ) u_sub (
        .original(orig_r),
        .blurred(blurred_w),
        .high_freq(high_w)
    );

    gain_scale #(
        .PIXEL_W(PIXEL_W),
        .GAIN_W(GAIN_W)
    ) u_gain (
        .high_freq(high_w),
        .gain(gain_r),
        .scaled(scaled_w)
    );

    reconstruct_sat #(
        .PIXEL_W(PIXEL_W),
        .GAIN_W(GAIN_W)
    ) u_reconstruct (
        .original(orig_r),
        .scaled(scaled_w),
        .pixel_out(result_w)
    );

    assign pixel_out = result_w;
    assign valid_out = valid_r;

    always @(posedge clk) begin
        if (rst) begin
            x <= 0;
            y <= 0;
            cur_l1 <= 0;
            cur_l2 <= 0;
            row1_l1 <= 0;
            row1_l2 <= 0;
            row0_l1 <= 0;
            row0_l2 <= 0;
            w00_r <= 0; w01_r <= 0; w02_r <= 0;
            w10_r <= 0; w11_r <= 0; w12_r <= 0;
            w20_r <= 0; w21_r <= 0; w22_r <= 0;
            orig_r <= 0;
            gain_r <= 0;
            valid_r <= 0;
            for (i = 0; i < IMG_WIDTH; i = i + 1) begin
                line1[i] <= 0;
                line2[i] <= 0;
            end
        end else begin
            valid_r <= valid_in;

            if (valid_in) begin
                orig_r <= pixel_in;
                gain_r <= gain;

                w00_r <= (y >= 2 && x >= 2) ? row0_l2 : {PIXEL_W{1'b0}};
                w01_r <= (y >= 2 && x >= 1) ? row0_l1 : {PIXEL_W{1'b0}};
                w02_r <= (y >= 2) ? line2[x] : {PIXEL_W{1'b0}};

                w10_r <= (y >= 1 && x >= 2) ? row1_l2 : {PIXEL_W{1'b0}};
                w11_r <= (y >= 1 && x >= 1) ? row1_l1 : {PIXEL_W{1'b0}};
                w12_r <= (y >= 1) ? line1[x] : {PIXEL_W{1'b0}};

                w20_r <= (x >= 2) ? cur_l2 : {PIXEL_W{1'b0}};
                w21_r <= (x >= 1) ? cur_l1 : {PIXEL_W{1'b0}};
                w22_r <= pixel_in;

                line2[x] <= line1[x];
                line1[x] <= pixel_in;

                cur_l2 <= (x == IMG_WIDTH-1) ? {PIXEL_W{1'b0}} : cur_l1;
                cur_l1 <= (x == IMG_WIDTH-1) ? {PIXEL_W{1'b0}} : pixel_in;

                row1_l2 <= (x == IMG_WIDTH-1) ? {PIXEL_W{1'b0}} : row1_l1;
                row1_l1 <= (x == IMG_WIDTH-1) ? {PIXEL_W{1'b0}} : line1[x];

                row0_l2 <= (x == IMG_WIDTH-1) ? {PIXEL_W{1'b0}} : row0_l1;
                row0_l1 <= (x == IMG_WIDTH-1) ? {PIXEL_W{1'b0}} : line2[x];

                if (x == IMG_WIDTH-1) begin
                    x <= 0;
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