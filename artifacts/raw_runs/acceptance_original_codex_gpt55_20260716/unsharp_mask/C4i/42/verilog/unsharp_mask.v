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
    localparam SCALE_W = DIFF_W + GAIN_W + 1;

    reg [PIXEL_W-1:0] line0 [0:IMG_WIDTH-1];
    reg [PIXEL_W-1:0] line1 [0:IMG_WIDTH-1];

    reg [PIXEL_W-1:0] cur_d1, cur_d2;
    reg [PIXEL_W-1:0] row1_d1, row1_d2;
    reg [PIXEL_W-1:0] row2_d1, row2_d2;

    reg [31:0] col;
    reg [31:0] row;

    wire [PIXEL_W-1:0] row1_pix;
    wire [PIXEL_W-1:0] row2_pix;

    assign row1_pix = (row >= 1) ? line0[col] : {PIXEL_W{1'b0}};
    assign row2_pix = (row >= 2) ? line1[col] : {PIXEL_W{1'b0}};

    wire [PIXEL_W-1:0] w00, w01, w02;
    wire [PIXEL_W-1:0] w10, w11, w12;
    wire [PIXEL_W-1:0] w20, w21, w22;

    assign w00 = (row >= 2 && col >= 2) ? row2_d2 : {PIXEL_W{1'b0}};
    assign w01 = (row >= 2 && col >= 1) ? row2_d1 : {PIXEL_W{1'b0}};
    assign w02 = (row >= 2)             ? row2_pix : {PIXEL_W{1'b0}};

    assign w10 = (row >= 1 && col >= 2) ? row1_d2 : {PIXEL_W{1'b0}};
    assign w11 = (row >= 1 && col >= 1) ? row1_d1 : {PIXEL_W{1'b0}};
    assign w12 = (row >= 1)             ? row1_pix : {PIXEL_W{1'b0}};

    assign w20 = (col >= 2) ? cur_d2 : {PIXEL_W{1'b0}};
    assign w21 = (col >= 1) ? cur_d1 : {PIXEL_W{1'b0}};
    assign w22 = pixel_in;

    wire [PIXEL_W-1:0] blurred;
    wire signed [DIFF_W-1:0] high_freq;
    wire signed [SCALE_W-1:0] scaled_high;
    wire [PIXEL_W-1:0] sharpened;

    gaussian3x3_blur #(
        .PIXEL_W(PIXEL_W)
    ) u_blur (
        .p00(w00), .p01(w01), .p02(w02),
        .p10(w10), .p11(w11), .p12(w12),
        .p20(w20), .p21(w21), .p22(w22),
        .blurred(blurred)
    );

    high_frequency #(
        .PIXEL_W(PIXEL_W),
        .DIFF_W(DIFF_W)
    ) u_high_frequency (
        .original(pixel_in),
        .blurred(blurred),
        .diff(high_freq)
    );

    gain_scale #(
        .GAIN_W(GAIN_W),
        .DIFF_W(DIFF_W),
        .SCALE_W(SCALE_W)
    ) u_gain_scale (
        .diff(high_freq),
        .gain(gain),
        .scaled(scaled_high)
    );

    reconstruct_saturate #(
        .PIXEL_W(PIXEL_W),
        .SCALE_W(SCALE_W)
    ) u_reconstruct (
        .original(pixel_in),
        .scaled_diff(scaled_high),
        .pixel_out(sharpened)
    );

    reg [PIXEL_W-1:0] pixel_out_r;
    reg valid_out_r;

    assign pixel_out = pixel_out_r;
    assign valid_out = valid_out_r;

    integer i;
    always @(posedge clk) begin
        if (rst) begin
            col <= 0;
            row <= 0;
            cur_d1 <= 0;
            cur_d2 <= 0;
            row1_d1 <= 0;
            row1_d2 <= 0;
            row2_d1 <= 0;
            row2_d2 <= 0;
            pixel_out_r <= 0;
            valid_out_r <= 0;
            for (i = 0; i < IMG_WIDTH; i = i + 1) begin
                line0[i] <= 0;
                line1[i] <= 0;
            end
        end else begin
            valid_out_r <= valid_in;

            if (valid_in) begin
                pixel_out_r <= sharpened;

                line1[col] <= line0[col];
                line0[col] <= pixel_in;

                cur_d2 <= cur_d1;
                cur_d1 <= pixel_in;

                row1_d2 <= row1_d1;
                row1_d1 <= row1_pix;

                row2_d2 <= row2_d1;
                row2_d1 <= row2_pix;

                if (col == IMG_WIDTH-1) begin
                    col <= 0;
                    if (row == IMG_HEIGHT-1)
                        row <= 0;
                    else
                        row <= row + 1;

                    cur_d1 <= 0;
                    cur_d2 <= 0;
                    row1_d1 <= 0;
                    row1_d2 <= 0;
                    row2_d1 <= 0;
                    row2_d2 <= 0;
                end else begin
                    col <= col + 1;
                end
            end
        end
    end

endmodule