`timescale 1ns/1ps

module conv2d #(
    parameter DATA_W      = 8,
    parameter IMG_WIDTH   = 64,
    parameter KERNEL_SIZE = 3,
    parameter GAIN_W      = 4
) (
    input                       clk,
    input                       rst,
    input                       valid_in,
    input      [DATA_W-1:0]     pixel_in,
    output reg                  valid_out,
    output reg [DATA_W+GAIN_W-1:0] pixel_out
);

    localparam OUT_W = DATA_W + GAIN_W;
    localparam ACC_W = DATA_W + GAIN_W + 8;
    localparam HALF  = KERNEL_SIZE / 2;
    localparam WIN_PIXELS = KERNEL_SIZE * KERNEL_SIZE;

    integer i;
    integer r;
    integer c;

    reg [DATA_W-1:0] linebuf [0:(KERNEL_SIZE > 1 ? KERNEL_SIZE-2 : 0)][0:IMG_WIDTH-1];
    reg [DATA_W-1:0] hshift  [0:KERNEL_SIZE-1][0:KERNEL_SIZE-1];

    reg [31:0] col_count;
    reg [31:0] row_count;

    wire at_last_col;
    wire window_valid_now;
    wire [DATA_W*KERNEL_SIZE-1:0] column_pixels;
    wire [DATA_W*WIN_PIXELS-1:0] window_flat;
    wire [ACC_W-1:0] mac_value;
    wire [OUT_W-1:0] saturated_value;

    conv2d_coord #(
        .IMG_WIDTH(IMG_WIDTH),
        .KERNEL_SIZE(KERNEL_SIZE)
    ) u_coord (
        .col_count(col_count),
        .row_count(row_count),
        .at_last_col(at_last_col),
        .window_valid(window_valid_now)
    );

    genvar gr;
    generate
        for (gr = 0; gr < KERNEL_SIZE; gr = gr + 1) begin : GEN_COL_PIX
            assign column_pixels[gr*DATA_W +: DATA_W] = hshift[gr][0];
        end
    endgenerate

    conv2d_window_pack #(
        .DATA_W(DATA_W),
        .KERNEL_SIZE(KERNEL_SIZE)
    ) u_window_pack (
        .window_in_flat(flatten_hshift()),
        .window_out_flat(window_flat)
    );

    conv2d_mac #(
        .DATA_W(DATA_W),
        .KERNEL_SIZE(KERNEL_SIZE),
        .GAIN_W(GAIN_W),
        .ACC_W(ACC_W)
    ) u_mac (
        .window_flat(window_flat),
        .mac_out(mac_value)
    );

    conv2d_saturate #(
        .IN_W(ACC_W),
        .OUT_W(OUT_W)
    ) u_saturate (
        .value_in(mac_value),
        .value_out(saturated_value)
    );

    function [DATA_W*WIN_PIXELS-1:0] flatten_hshift;
        integer fr;
        integer fc;
        begin
            flatten_hshift = {DATA_W*WIN_PIXELS{1'b0}};
            for (fr = 0; fr < KERNEL_SIZE; fr = fr + 1) begin
                for (fc = 0; fc < KERNEL_SIZE; fc = fc + 1) begin
                    flatten_hshift[(fr*KERNEL_SIZE+fc)*DATA_W +: DATA_W] = hshift[fr][fc];
                end
            end
        end
    endfunction

    always @(posedge clk) begin
        if (rst) begin
            valid_out <= 1'b0;
            pixel_out <= {OUT_W{1'b0}};
            col_count <= 32'd0;
            row_count <= 32'd0;

            for (r = 0; r < KERNEL_SIZE; r = r + 1) begin
                for (c = 0; c < KERNEL_SIZE; c = c + 1) begin
                    hshift[r][c] <= {DATA_W{1'b0}};
                end
            end

            for (r = 0; r < (KERNEL_SIZE > 1 ? KERNEL_SIZE-1 : 1); r = r + 1) begin
                for (c = 0; c < IMG_WIDTH; c = c + 1) begin
                    linebuf[r][c] <= {DATA_W{1'b0}};
                end
            end
        end else begin
            valid_out <= 1'b0;

            if (valid_in) begin
                for (r = 0; r < KERNEL_SIZE; r = r + 1) begin
                    for (c = KERNEL_SIZE-1; c > 0; c = c - 1) begin
                        hshift[r][c] <= hshift[r][c-1];
                    end
                end

                hshift[0][0] <= pixel_in;
                if (KERNEL_SIZE > 1) begin
                    for (r = 1; r < KERNEL_SIZE; r = r + 1) begin
                        hshift[r][0] <= linebuf[r-1][col_count];
                    end

                    linebuf[0][col_count] <= pixel_in;
                    for (r = 1; r < KERNEL_SIZE-1; r = r + 1) begin
                        linebuf[r][col_count] <= linebuf[r-1][col_count];
                    end
                end

                valid_out <= window_valid_now;
                pixel_out <= saturated_value;

                if (at_last_col) begin
                    col_count <= 32'd0;
                    row_count <= row_count + 32'd1;
                end else begin
                    col_count <= col_count + 32'd1;
                end
            end
        end
    end

endmodule