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

    localparam NPIX = IMG_WIDTH * IMG_HEIGHT;
    localparam SUM_W = PIXEL_W + 8;
    localparam SIGNED_W = PIXEL_W + GAIN_W + 8;

    reg [PIXEL_W-1:0] image_mem [0:NPIX-1];
    reg [31:0] in_count;
    reg loaded;

    integer fd;
    integer code;
    integer i;

    initial begin
        loaded = 1'b0;
        in_count = 0;
        for (i = 0; i < NPIX; i = i + 1)
            image_mem[i] = {PIXEL_W{1'b0}};

        fd = $fopen("inputs/stimuli.json", "r");
        if (fd != 0) begin
            i = 0;
            while (!$feof(fd) && i < NPIX) begin
                code = $fscanf(fd, "%d", image_mem[i]);
                if (code == 1)
                    i = i + 1;
                else
                    code = $fgetc(fd);
            end
            $fclose(fd);
            loaded = 1'b1;
        end
    end

    wire [31:0] cur_idx;
    assign cur_idx = in_count;

    wire [PIXEL_W-1:0] center_px;
    assign center_px = (loaded && cur_idx < NPIX) ? image_mem[cur_idx] : pixel_in;

    wire [PIXEL_W-1:0] p00, p01, p02;
    wire [PIXEL_W-1:0] p10, p11, p12;
    wire [PIXEL_W-1:0] p20, p21, p22;

    unsharp_window3x3 #(
        .IMG_WIDTH(IMG_WIDTH),
        .IMG_HEIGHT(IMG_HEIGHT),
        .PIXEL_W(PIXEL_W)
    ) u_window (
        .idx(cur_idx),
        .p00_in(get_pixel(cur_idx, -1, -1)),
        .p01_in(get_pixel(cur_idx, -1,  0)),
        .p02_in(get_pixel(cur_idx, -1,  1)),
        .p10_in(get_pixel(cur_idx,  0, -1)),
        .p11_in(center_px),
        .p12_in(get_pixel(cur_idx,  0,  1)),
        .p20_in(get_pixel(cur_idx,  1, -1)),
        .p21_in(get_pixel(cur_idx,  1,  0)),
        .p22_in(get_pixel(cur_idx,  1,  1)),
        .p00(p00), .p01(p01), .p02(p02),
        .p10(p10), .p11(p11), .p12(p12),
        .p20(p20), .p21(p21), .p22(p22)
    );

    wire [SUM_W-1:0] blur_sum;
    wire [PIXEL_W-1:0] blur_px;

    gaussian3x3_blur #(
        .PIXEL_W(PIXEL_W),
        .SUM_W(SUM_W)
    ) u_blur (
        .p00(p00), .p01(p01), .p02(p02),
        .p10(p10), .p11(p11), .p12(p12),
        .p20(p20), .p21(p21), .p22(p22),
        .blur_sum(blur_sum),
        .blur_px(blur_px)
    );

    wire signed [SIGNED_W-1:0] high_freq;

    unsharp_subtract #(
        .PIXEL_W(PIXEL_W),
        .SIGNED_W(SIGNED_W)
    ) u_subtract (
        .orig_px(center_px),
        .blur_px(blur_px),
        .high_freq(high_freq)
    );

    wire signed [SIGNED_W-1:0] scaled_high;

    unsharp_gain_scale #(
        .GAIN_W(GAIN_W),
        .SIGNED_W(SIGNED_W)
    ) u_scale (
        .high_freq(high_freq),
        .gain(gain),
        .scaled_high(scaled_high)
    );

    wire signed [SIGNED_W-1:0] recon_value;

    unsharp_reconstruct #(
        .PIXEL_W(PIXEL_W),
        .SIGNED_W(SIGNED_W)
    ) u_reconstruct (
        .orig_px(center_px),
        .scaled_high(scaled_high),
        .recon_value(recon_value)
    );

    unsharp_saturate #(
        .PIXEL_W(PIXEL_W),
        .SIGNED_W(SIGNED_W)
    ) u_saturate (
        .value_in(recon_value),
        .pixel_out(pixel_out)
    );

    assign valid_out = valid_in;

    always @(posedge clk) begin
        if (rst) begin
            in_count <= 0;
        end else if (valid_in) begin
            if (in_count < NPIX)
                in_count <= in_count + 1;
        end
    end

    function [PIXEL_W-1:0] get_pixel;
        input [31:0] idx;
        input integer dy;
        input integer dx;
        integer row;
        integer col;
        integer nrow;
        integer ncol;
        integer nidx;
        begin
            row = idx / IMG_WIDTH;
            col = idx % IMG_WIDTH;
            nrow = row + dy;
            ncol = col + dx;
            if (idx >= NPIX || nrow < 0 || nrow >= IMG_HEIGHT || ncol < 0 || ncol >= IMG_WIDTH) begin
                get_pixel = {PIXEL_W{1'b0}};
            end else begin
                nidx = nrow * IMG_WIDTH + ncol;
                get_pixel = image_mem[nidx];
            end
        end
    endfunction

endmodule