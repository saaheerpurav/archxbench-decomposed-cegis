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

    localparam X_W = 16;
    localparam Y_W = 16;
    localparam DIFF_W = PIXEL_W + 2;
    localparam SCALE_W = PIXEL_W + GAIN_W + 3;

    reg [PIXEL_W-1:0] line0 [0:IMG_WIDTH-1];
    reg [PIXEL_W-1:0] line1 [0:IMG_WIDTH-1];

    reg [PIXEL_W-1:0] cur_d1, cur_d2;
    reg [X_W-1:0] x_pos;
    reg [Y_W-1:0] y_pos;

    reg [PIXEL_W-1:0] pixel_out_r;
    reg valid_out_r;

    wire [PIXEL_W-1:0] w00, w01, w02;
    wire [PIXEL_W-1:0] w10, w11, w12;
    wire [PIXEL_W-1:0] w20, w21, w22;

    wire [PIXEL_W-1:0] blurred_pixel;
    wire signed [DIFF_W-1:0] high_freq;
    wire signed [SCALE_W-1:0] scaled_high_freq;
    wire signed [SCALE_W:0] reconstructed_pixel;
    wire [PIXEL_W-1:0] clamped_pixel;

    assign w00 = (valid_in && y_pos >= 2 && x_pos >= 2) ? line1[x_pos-2] : {PIXEL_W{1'b0}};
    assign w01 = (valid_in && y_pos >= 2 && x_pos >= 1) ? line1[x_pos-1] : {PIXEL_W{1'b0}};
    assign w02 = (valid_in && y_pos >= 2)              ? line1[x_pos]   : {PIXEL_W{1'b0}};

    assign w10 = (valid_in && y_pos >= 1 && x_pos >= 2) ? line0[x_pos-2] : {PIXEL_W{1'b0}};
    assign w11 = (valid_in && y_pos >= 1 && x_pos >= 1) ? line0[x_pos-1] : {PIXEL_W{1'b0}};
    assign w12 = (valid_in && y_pos >= 1)              ? line0[x_pos]   : {PIXEL_W{1'b0}};

    assign w20 = (valid_in && x_pos >= 2) ? cur_d2   : {PIXEL_W{1'b0}};
    assign w21 = (valid_in && x_pos >= 1) ? cur_d1   : {PIXEL_W{1'b0}};
    assign w22 = valid_in                 ? pixel_in : {PIXEL_W{1'b0}};

    gaussian3x3_blur #(
        .PIXEL_W(PIXEL_W)
    ) u_gaussian3x3_blur (
        .p00(w00), .p01(w01), .p02(w02),
        .p10(w10), .p11(w11), .p12(w12),
        .p20(w20), .p21(w21), .p22(w22),
        .blurred(blurred_pixel)
    );

    unsharp_subtract #(
        .PIXEL_W(PIXEL_W),
        .DIFF_W(DIFF_W)
    ) u_unsharp_subtract (
        .original(pixel_in),
        .blurred(blurred_pixel),
        .diff(high_freq)
    );

    unsharp_gain_scale #(
        .GAIN_W(GAIN_W),
        .DIFF_W(DIFF_W),
        .SCALE_W(SCALE_W)
    ) u_unsharp_gain_scale (
        .diff(high_freq),
        .gain(gain),
        .scaled(scaled_high_freq)
    );

    unsharp_reconstruct #(
        .PIXEL_W(PIXEL_W),
        .SCALE_W(SCALE_W)
    ) u_unsharp_reconstruct (
        .original(pixel_in),
        .scaled_diff(scaled_high_freq),
        .reconstructed(reconstructed_pixel)
    );

    pixel_saturate #(
        .PIXEL_W(PIXEL_W),
        .IN_W(SCALE_W+1)
    ) u_pixel_saturate (
        .value_in(reconstructed_pixel),
        .pixel_out(clamped_pixel)
    );

    assign pixel_out = pixel_out_r;
    assign valid_out = valid_out_r;

    integer i;

    always @(posedge clk) begin
        if (rst) begin
            x_pos <= {X_W{1'b0}};
            y_pos <= {Y_W{1'b0}};
            cur_d1 <= {PIXEL_W{1'b0}};
            cur_d2 <= {PIXEL_W{1'b0}};
            pixel_out_r <= {PIXEL_W{1'b0}};
            valid_out_r <= 1'b0;

            for (i = 0; i < IMG_WIDTH; i = i + 1) begin
                line0[i] <= {PIXEL_W{1'b0}};
                line1[i] <= {PIXEL_W{1'b0}};
            end
        end else begin
            valid_out_r <= valid_in;

            if (valid_in) begin
                pixel_out_r <= clamped_pixel;

                line1[x_pos] <= line0[x_pos];
                line0[x_pos] <= pixel_in;

                cur_d2 <= cur_d1;
                cur_d1 <= pixel_in;

                if (x_pos == IMG_WIDTH-1) begin
                    x_pos <= {X_W{1'b0}};
                    cur_d1 <= {PIXEL_W{1'b0}};
                    cur_d2 <= {PIXEL_W{1'b0}};

                    if (y_pos == IMG_HEIGHT-1)
                        y_pos <= {Y_W{1'b0}};
                    else
                        y_pos <= y_pos + 1'b1;
                end else begin
                    x_pos <= x_pos + 1'b1;
                end
            end else begin
                pixel_out_r <= {PIXEL_W{1'b0}};
            end
        end
    end

endmodule