`timescale 1ns/1ps

module conv2d #(
    parameter DATA_W      = 8,
    parameter IMG_WIDTH   = 64,
    parameter KERNEL_SIZE = 3,
    parameter GAIN_W      = 4
) (
    input                          clk,
    input                          rst,
    input                          valid_in,
    input      [DATA_W-1:0]        pixel_in,
    output reg                     valid_out,
    output reg [DATA_W+GAIN_W-1:0] pixel_out
);
    localparam OUT_W   = DATA_W + GAIN_W;
    localparam ACC_W   = DATA_W + GAIN_W + 8;
    localparam RADIUS  = KERNEL_SIZE / 2;
    localparam HIST_N  = (KERNEL_SIZE * IMG_WIDTH) + KERNEL_SIZE + 2;
    localparam HIST_W  = HIST_N * DATA_W;
    localparam WIN_N   = KERNEL_SIZE * KERNEL_SIZE;
    localparam WIN_W   = WIN_N * DATA_W;
    localparam COEFF_W = GAIN_W + 4;
    localparam COEFFS_W = WIN_N * COEFF_W;

    reg [DATA_W-1:0] history [0:HIST_N-1];
    reg [31:0]       pix_count;
    reg [31:0]       row_count;
    reg [31:0]       col_count;

    integer i;

    wire [HIST_W-1:0] history_flat;
    wire [WIN_W-1:0]  window_flat;
    wire [COEFFS_W-1:0] coeffs_flat;
    wire               window_valid;
    wire [ACC_W-1:0]   mac_sum;
    wire [OUT_W-1:0]   rounded_pixel;

    genvar g;
    generate
        for (g = 0; g < HIST_N; g = g + 1) begin : FLATTEN_HISTORY
            assign history_flat[(g*DATA_W) +: DATA_W] = history[g];
        end
    endgenerate

    conv2d_default_coeffs #(
        .KERNEL_SIZE(KERNEL_SIZE),
        .COEFF_W(COEFF_W)
    ) u_coeffs (
        .coeffs_flat(coeffs_flat)
    );

    conv2d_window_builder #(
        .DATA_W(DATA_W),
        .IMG_WIDTH(IMG_WIDTH),
        .KERNEL_SIZE(KERNEL_SIZE),
        .HIST_N(HIST_N)
    ) u_window (
        .history_flat(history_flat),
        .pixel_in(pixel_in),
        .pix_count(pix_count),
        .valid_in(valid_in),
        .window_flat(window_flat),
        .window_valid(window_valid)
    );

    conv2d_dot_product #(
        .DATA_W(DATA_W),
        .COEFF_W(COEFF_W),
        .KERNEL_SIZE(KERNEL_SIZE),
        .ACC_W(ACC_W)
    ) u_mac (
        .window_flat(window_flat),
        .coeffs_flat(coeffs_flat),
        .sum(mac_sum)
    );

    conv2d_output_cast #(
        .ACC_W(ACC_W),
        .OUT_W(OUT_W)
    ) u_cast (
        .sum_in(mac_sum),
        .pixel_out(rounded_pixel)
    );

    always @(posedge clk) begin
        if (rst) begin
            pix_count <= 0;
            row_count <= 0;
            col_count <= 0;
            valid_out <= 0;
            pixel_out <= 0;
            for (i = 0; i < HIST_N; i = i + 1)
                history[i] <= 0;
        end else begin
            valid_out <= 0;

            if (valid_in) begin
                pixel_out <= rounded_pixel;
                valid_out <= window_valid;

                for (i = HIST_N-1; i > 0; i = i - 1)
                    history[i] <= history[i-1];
                history[0] <= pixel_in;

                pix_count <= pix_count + 1;

                if (col_count == IMG_WIDTH-1) begin
                    col_count <= 0;
                    row_count <= row_count + 1;
                end else begin
                    col_count <= col_count + 1;
                end
            end
        end
    end
endmodule