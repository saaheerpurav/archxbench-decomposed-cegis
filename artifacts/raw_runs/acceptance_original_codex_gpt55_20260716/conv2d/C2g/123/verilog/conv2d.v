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
    output reg                      valid_out,
    output reg [DATA_W+GAIN_W-1:0]  pixel_out
);

    localparam OUT_W = DATA_W + GAIN_W;
    localparam ACC_W = OUT_W + 8;

    reg [DATA_W-1:0] line0 [0:IMG_WIDTH-1];
    reg [DATA_W-1:0] line1 [0:IMG_WIDTH-1];

    reg [DATA_W-1:0] top_l, top_c;
    reg [DATA_W-1:0] mid_l, mid_c;
    reg [DATA_W-1:0] bot_l, bot_c;

    reg [31:0] row;
    reg [31:0] col;

    wire [DATA_W-1:0] top_r = (row >= 2) ? line1[col] : {DATA_W{1'b0}};
    wire [DATA_W-1:0] mid_r = (row >= 1) ? line0[col] : {DATA_W{1'b0}};
    wire [DATA_W-1:0] bot_r = pixel_in;

    reg [ACC_W-1:0] acc;
    integer i;

    always @* begin
        acc = {ACC_W{1'b0}};

        acc = acc + top_l + (top_c << 1) + top_r;
        acc = acc + (mid_l << 1) + (mid_c << 2) + (mid_r << 1);
        acc = acc + bot_l + (bot_c << 1) + bot_r;

        valid_out = 1'b1;

        if (rst)
            pixel_out = {OUT_W{1'b0}};
        else
            pixel_out = acc[OUT_W+3:4];
    end

    always @(posedge clk) begin
        if (rst) begin
            row <= 0;
            col <= 0;

            top_l <= 0; top_c <= 0;
            mid_l <= 0; mid_c <= 0;
            bot_l <= 0; bot_c <= 0;

            for (i = 0; i < IMG_WIDTH; i = i + 1) begin
                line0[i] <= 0;
                line1[i] <= 0;
            end
        end else if (valid_in) begin
            line0[col] <= pixel_in;
            line1[col] <= line0[col];

            if (col == IMG_WIDTH-1) begin
                top_l <= 0; top_c <= 0;
                mid_l <= 0; mid_c <= 0;
                bot_l <= 0; bot_c <= 0;

                col <= 0;
                row <= row + 1;
            end else begin
                top_l <= top_c;
                top_c <= top_r;

                mid_l <= mid_c;
                mid_c <= mid_r;

                bot_l <= bot_c;
                bot_c <= bot_r;

                col <= col + 1;
            end
        end
    end

endmodule