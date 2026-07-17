`timescale 1ns/1ps

module conv2d #(
    parameter DATA_W      = 8,
    parameter IMG_WIDTH   = 64,
    parameter KERNEL_SIZE = 3,
    parameter GAIN_W      = 4
) (
    input                           clk,
    input                           rst,
    input                           valid_in,
    input      [DATA_W-1:0]         pixel_in,
    output                          valid_out,
    output     [DATA_W+GAIN_W-1:0]  pixel_out
);

    localparam OUT_W = DATA_W + GAIN_W;
    localparam ACC_W = OUT_W + 8;

    assign valid_out = !rst;

    reg [DATA_W-1:0] line0 [0:IMG_WIDTH-1];
    reg [DATA_W-1:0] line1 [0:IMG_WIDTH-1];

    reg [DATA_W-1:0] t0_l, t0_c;
    reg [DATA_W-1:0] t1_l, t1_c;
    reg [DATA_W-1:0] t2_l, t2_c;

    reg [31:0] row;
    reg [31:0] col;

    wire [DATA_W-1:0] t0_r = (row >= 2) ? line1[col] : {DATA_W{1'b0}};
    wire [DATA_W-1:0] t1_r = (row >= 1) ? line0[col] : {DATA_W{1'b0}};
    wire [DATA_W-1:0] t2_r = pixel_in;

    wire border_top    = (row < 2);
    wire border_left   = (col == 0);
    wire border_right  = (col == IMG_WIDTH-1);

    wire [DATA_W-1:0] w00 = (border_top || border_left)  ? 0 : t0_l;
    wire [DATA_W-1:0] w01 = (border_top)                ? 0 : t0_c;
    wire [DATA_W-1:0] w02 = (border_top || border_right) ? 0 : t0_r;

    wire [DATA_W-1:0] w10 = (border_left)  ? 0 : t1_l;
    wire [DATA_W-1:0] w11 = t1_c;
    wire [DATA_W-1:0] w12 = (border_right) ? 0 : t1_r;

    wire [DATA_W-1:0] w20 = (border_left)  ? 0 : t2_l;
    wire [DATA_W-1:0] w21 = t2_c;
    wire [DATA_W-1:0] w22 = (border_right) ? 0 : t2_r;

    wire [ACC_W-1:0] acc =
        w00 + (w01 << 1) + w02 +
        (w10 << 1) + (w11 << 2) + (w12 << 1) +
        w20 + (w21 << 1) + w22;

    assign pixel_out = acc >> 4;

    integer i;

    always @(posedge clk) begin
        if (rst) begin
            row <= 0;
            col <= 0;

            t0_l <= 0; t0_c <= 0;
            t1_l <= 0; t1_c <= 0;
            t2_l <= 0; t2_c <= 0;

            for (i = 0; i < IMG_WIDTH; i = i + 1) begin
                line0[i] <= 0;
                line1[i] <= 0;
            end
        end else if (valid_in) begin
            line1[col] <= line0[col];
            line0[col] <= pixel_in;

            if (col == 0) begin
                t0_l <= 0;
                t1_l <= 0;
                t2_l <= 0;
            end else begin
                t0_l <= t0_c;
                t1_l <= t1_c;
                t2_l <= t2_c;
            end

            t0_c <= t0_r;
            t1_c <= t1_r;
            t2_c <= t2_r;

            if (col == IMG_WIDTH-1) begin
                col <= 0;
                row <= row + 1;
            end else begin
                col <= col + 1;
            end
        end
    end

endmodule