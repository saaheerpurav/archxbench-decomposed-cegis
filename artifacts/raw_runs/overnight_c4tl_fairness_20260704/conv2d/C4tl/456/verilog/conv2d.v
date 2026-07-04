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
    localparam RADIUS = KERNEL_SIZE / 2;
    localparam MAX_PIXELS = IMG_WIDTH * IMG_WIDTH;

    reg [DATA_W-1:0] frame_mem [0:MAX_PIXELS-1];
    reg [31:0] in_count;
    reg [31:0] out_count;

    wire [31:0] out_row;
    wire [31:0] out_col;
    wire [ACC_W-1:0] conv_sum;
    wire [OUT_W-1:0] clipped_sum;

    assign out_row = out_count / IMG_WIDTH;
    assign out_col = out_count % IMG_WIDTH;

    conv2d_kernel_mac #(
        .DATA_W(DATA_W),
        .IMG_WIDTH(IMG_WIDTH),
        .KERNEL_SIZE(KERNEL_SIZE),
        .GAIN_W(GAIN_W),
        .ACC_W(ACC_W)
    ) u_kernel_mac (
        .center_row(out_row),
        .center_col(out_col),
        .p00(conv2d_pixel_at(out_row, out_col, 0, 0)),
        .p01(conv2d_pixel_at(out_row, out_col, 0, 1)),
        .p02(conv2d_pixel_at(out_row, out_col, 0, 2)),
        .p10(conv2d_pixel_at(out_row, out_col, 1, 0)),
        .p11(conv2d_pixel_at(out_row, out_col, 1, 1)),
        .p12(conv2d_pixel_at(out_row, out_col, 1, 2)),
        .p20(conv2d_pixel_at(out_row, out_col, 2, 0)),
        .p21(conv2d_pixel_at(out_row, out_col, 2, 1)),
        .p22(conv2d_pixel_at(out_row, out_col, 2, 2)),
        .sum(conv_sum)
    );

    conv2d_output_clip #(
        .IN_W(ACC_W),
        .OUT_W(OUT_W)
    ) u_output_clip (
        .value_in(conv_sum),
        .value_out(clipped_sum)
    );

    integer init_i;

    initial begin
        for (init_i = 0; init_i < MAX_PIXELS; init_i = init_i + 1)
            frame_mem[init_i] = {DATA_W{1'b0}};
        in_count = 0;
        out_count = 0;
        valid_out = 1'b0;
        pixel_out = {OUT_W{1'b0}};
    end

    always @(posedge clk) begin
        if (rst) begin
            in_count  <= 0;
            out_count <= 0;
            valid_out <= 1'b0;
            pixel_out <= {OUT_W{1'b0}};
        end else begin
            valid_out <= 1'b1;

            if (valid_in && in_count < MAX_PIXELS) begin
                frame_mem[in_count] <= pixel_in;
                in_count <= in_count + 1;
            end

            pixel_out <= clipped_sum;

            if (out_count < MAX_PIXELS-1)
                out_count <= out_count + 1;
        end
    end

    function [DATA_W-1:0] conv2d_pixel_at;
        input [31:0] center_r;
        input [31:0] center_c;
        input integer kr;
        input integer kc;

        integer rr;
        integer cc;
        integer idx;
        begin
            rr = center_r + kr - RADIUS;
            cc = center_c + kc - RADIUS;

            if (rr < 0 || rr >= IMG_WIDTH || cc < 0 || cc >= IMG_WIDTH) begin
                conv2d_pixel_at = {DATA_W{1'b0}};
            end else begin
                idx = rr * IMG_WIDTH + cc;

                if (idx < in_count)
                    conv2d_pixel_at = frame_mem[idx];
                else if (valid_in && idx == in_count)
                    conv2d_pixel_at = pixel_in;
                else
                    conv2d_pixel_at = {DATA_W{1'b0}};
            end
        end
    endfunction

endmodule