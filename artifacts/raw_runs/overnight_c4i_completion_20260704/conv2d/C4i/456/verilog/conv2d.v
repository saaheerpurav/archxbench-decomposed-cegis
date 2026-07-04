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
    localparam ACC_W = DATA_W + GAIN_W + 8;
    localparam TAPS  = KERNEL_SIZE * KERNEL_SIZE;

    reg [DATA_W-1:0] linebuf [0:KERNEL_SIZE-2][0:IMG_WIDTH-1];
    reg [DATA_W-1:0] window  [0:KERNEL_SIZE-1][0:KERNEL_SIZE-1];

    reg [31:0] row_count;
    reg [31:0] col_count;

    wire [31:0] next_row;
    wire [31:0] next_col;
    wire        end_of_line;

    wire [TAPS*DATA_W-1:0] flat_window;
    wire [TAPS*16-1:0]     flat_coeffs;
    wire signed [ACC_W-1:0] mac_result;
    wire [OUT_W-1:0]       clamped_result;

    integer r, c, i;

    conv2d_position #(
        .IMG_WIDTH(IMG_WIDTH)
    ) u_position (
        .row_in(row_count),
        .col_in(col_count),
        .valid_in(valid_in),
        .row_out(next_row),
        .col_out(next_col),
        .end_of_line(end_of_line)
    );

    conv2d_window_pack #(
        .DATA_W(DATA_W),
        .KERNEL_SIZE(KERNEL_SIZE)
    ) u_window_pack (
        .w00(window[0][0]), .w01(window[0][1]), .w02(window[0][2]),
        .w10(window[1][0]), .w11(window[1][1]), .w12(window[1][2]),
        .w20(window[2][0]), .w21(window[2][1]), .w22(window[2][2]),
        .flat_window(flat_window)
    );

    conv2d_coeffs #(
        .KERNEL_SIZE(KERNEL_SIZE)
    ) u_coeffs (
        .flat_coeffs(flat_coeffs)
    );

    conv2d_mac #(
        .DATA_W(DATA_W),
        .KERNEL_SIZE(KERNEL_SIZE),
        .ACC_W(ACC_W)
    ) u_mac (
        .flat_window(flat_window),
        .flat_coeffs(flat_coeffs),
        .result(mac_result)
    );

    conv2d_saturate #(
        .IN_W(ACC_W),
        .OUT_W(OUT_W)
    ) u_saturate (
        .value_in(mac_result),
        .value_out(clamped_result)
    );

    always @(posedge clk) begin
        if (rst) begin
            row_count <= 0;
            col_count <= 0;
            valid_out <= 0;
            pixel_out <= 0;

            for (r = 0; r < KERNEL_SIZE-1; r = r + 1)
                for (c = 0; c < IMG_WIDTH; c = c + 1)
                    linebuf[r][c] <= 0;

            for (r = 0; r < KERNEL_SIZE; r = r + 1)
                for (c = 0; c < KERNEL_SIZE; c = c + 1)
                    window[r][c] <= 0;
        end else begin
            valid_out <= 0;

            if (valid_in) begin
                for (r = 0; r < KERNEL_SIZE; r = r + 1)
                    for (c = 0; c < KERNEL_SIZE-1; c = c + 1)
                        window[r][c] <= window[r][c+1];

                window[KERNEL_SIZE-1][KERNEL_SIZE-1] <= pixel_in;

                for (r = 0; r < KERNEL_SIZE-1; r = r + 1)
                    window[r][KERNEL_SIZE-1] <= linebuf[KERNEL_SIZE-2-r][col_count];

                linebuf[0][col_count] <= pixel_in;
                for (i = 1; i < KERNEL_SIZE-1; i = i + 1)
                    linebuf[i][col_count] <= linebuf[i-1][col_count];

                row_count <= next_row;
                col_count <= next_col;

                valid_out <= 1;
                pixel_out <= clamped_result;
            end
        end
    end

endmodule