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

    localparam COORD_W = 16;
    localparam SUM_W   = PIXEL_W + 6;
    localparam DIFF_W  = PIXEL_W + 2;
    localparam PROD_W  = DIFF_W + GAIN_W;

    reg [PIXEL_W-1:0] line0 [0:IMG_WIDTH-1];
    reg [PIXEL_W-1:0] line1 [0:IMG_WIDTH-1];

    reg [PIXEL_W-1:0] cur_left1, cur_left2;
    reg [COORD_W-1:0] col;
    reg [COORD_W-1:0] row;

    integer i;

    wire first_col = (col == 0);
    wire second_col = (col == 1);
    wire first_row = (row == 0);
    wire second_row = (row == 1);

    wire [PIXEL_W-1:0] lb0_c  = first_row ? {PIXEL_W{1'b0}} : line0[col];
    wire [PIXEL_W-1:0] lb1_c  = (first_row || second_row) ? {PIXEL_W{1'b0}} : line1[col];

    wire [PIXEL_W-1:0] w00 = (first_row || second_row || first_col || second_col) ? {PIXEL_W{1'b0}} : line1[col-2];
    wire [PIXEL_W-1:0] w01 = (first_row || second_row || first_col)              ? {PIXEL_W{1'b0}} : line1[col-1];
    wire [PIXEL_W-1:0] w02 = (first_row || second_row)                            ? {PIXEL_W{1'b0}} : lb1_c;

    wire [PIXEL_W-1:0] w10 = (first_row || first_col || second_col) ? {PIXEL_W{1'b0}} : line0[col-2];
    wire [PIXEL_W-1:0] w11 = (first_row || first_col)              ? {PIXEL_W{1'b0}} : line0[col-1];
    wire [PIXEL_W-1:0] w12 = first_row                             ? {PIXEL_W{1'b0}} : lb0_c;

    wire [PIXEL_W-1:0] w20 = (first_col || second_col) ? {PIXEL_W{1'b0}} : cur_left2;
    wire [PIXEL_W-1:0] w21 = first_col                ? {PIXEL_W{1'b0}} : cur_left1;
    wire [PIXEL_W-1:0] w22 = pixel_in;

    wire [PIXEL_W-1:0] blurred;
    wire signed [DIFF_W-1:0] high_freq;
    wire signed [PROD_W-1:0] scaled_high;
    wire [PIXEL_W-1:0] sharpened;

    gaussian3x3_blur #(
        .PIXEL_W(PIXEL_W)
    ) u_blur (
        .p00(w00), .p01(w01), .p02(w02),
        .p10(w10), .p11(w11), .p12(w12),
        .p20(w20), .p21(w21), .p22(w22),
        .blurred(blurred)
    );

    unsharp_difference #(
        .PIXEL_W(PIXEL_W),
        .DIFF_W(DIFF_W)
    ) u_difference (
        .original(pixel_in),
        .blurred(blurred),
        .diff(high_freq)
    );

    unsharp_gain_scale #(
        .GAIN_W(GAIN_W),
        .DIFF_W(DIFF_W),
        .PROD_W(PROD_W)
    ) u_scale (
        .diff(high_freq),
        .gain(gain),
        .scaled(scaled_high)
    );

    unsharp_reconstruct #(
        .PIXEL_W(PIXEL_W),
        .PROD_W(PROD_W)
    ) u_reconstruct (
        .original(pixel_in),
        .scaled(scaled_high),
        .pixel_out(sharpened)
    );

    assign pixel_out = sharpened;
    assign valid_out = valid_in;

    always @(posedge clk) begin
        if (rst) begin
            col <= 0;
            row <= 0;
            cur_left1 <= 0;
            cur_left2 <= 0;
            for (i = 0; i < IMG_WIDTH; i = i + 1) begin
                line0[i] <= 0;
                line1[i] <= 0;
            end
        end else if (valid_in) begin
            line1[col] <= line0[col];
            line0[col] <= pixel_in;

            if (col == IMG_WIDTH-1) begin
                col <= 0;
                cur_left1 <= 0;
                cur_left2 <= 0;
                if (row == IMG_HEIGHT-1)
                    row <= 0;
                else
                    row <= row + 1'b1;
            end else begin
                col <= col + 1'b1;
                cur_left2 <= cur_left1;
                cur_left1 <= pixel_in;
            end
        end
    end

endmodule