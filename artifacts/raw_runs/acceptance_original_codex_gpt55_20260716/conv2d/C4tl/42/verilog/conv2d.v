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
    localparam TAP_COUNT = KERNEL_SIZE * KERNEL_SIZE;
    localparam ACC_W = OUT_W + 8;

    integer r;
    integer c;
    integer i;

    reg [DATA_W-1:0] linebuf [0:KERNEL_SIZE-2][0:IMG_WIDTH-1];
    reg [DATA_W-1:0] shift_window [0:KERNEL_SIZE-1][0:KERNEL_SIZE-1];

    reg [31:0] col_count;
    reg [31:0] pixel_count;

    wire [31:0] next_col;
    wire        end_of_line;

    wire [TAP_COUNT*DATA_W-1:0] window_flat;
    wire [TAP_COUNT*8-1:0]      coeff_flat;
    wire [ACC_W-1:0]            mac_sum;
    wire [OUT_W-1:0]            clipped_pixel;

    conv2d_coord #(
        .IMG_WIDTH(IMG_WIDTH)
    ) u_coord (
        .col_count(col_count),
        .next_col(next_col),
        .end_of_line(end_of_line)
    );

    conv2d_window_pack #(
        .DATA_W(DATA_W),
        .KERNEL_SIZE(KERNEL_SIZE)
    ) u_window_pack (
        .window_in(window_flat),
        .window_out(window_flat)
    );

    conv2d_coeffs #(
        .KERNEL_SIZE(KERNEL_SIZE)
    ) u_coeffs (
        .coeffs(coeff_flat)
    );

    conv2d_dot_product #(
        .DATA_W(DATA_W),
        .COEFF_W(8),
        .KERNEL_SIZE(KERNEL_SIZE),
        .ACC_W(ACC_W)
    ) u_dot_product (
        .pixels(window_flat),
        .coeffs(coeff_flat),
        .sum(mac_sum)
    );

    conv2d_saturate #(
        .IN_W(ACC_W),
        .OUT_W(OUT_W)
    ) u_saturate (
        .value_in(mac_sum),
        .value_out(clipped_pixel)
    );

    genvar gr;
    genvar gc;
    generate
        for (gr = 0; gr < KERNEL_SIZE; gr = gr + 1) begin : PACK_ROWS
            for (gc = 0; gc < KERNEL_SIZE; gc = gc + 1) begin : PACK_COLS
                assign window_flat[((gr*KERNEL_SIZE+gc+1)*DATA_W)-1 -: DATA_W] =
                    shift_window[gr][gc];
            end
        end
    endgenerate

    always @(posedge clk) begin
        if (rst) begin
            valid_out   <= 1'b0;
            pixel_out   <= {OUT_W{1'b0}};
            col_count   <= 32'd0;
            pixel_count <= 32'd0;

            for (r = 0; r < KERNEL_SIZE-1; r = r + 1) begin
                for (c = 0; c < IMG_WIDTH; c = c + 1) begin
                    linebuf[r][c] <= {DATA_W{1'b0}};
                end
            end

            for (r = 0; r < KERNEL_SIZE; r = r + 1) begin
                for (c = 0; c < KERNEL_SIZE; c = c + 1) begin
                    shift_window[r][c] <= {DATA_W{1'b0}};
                end
            end
        end else begin
            valid_out <= valid_in;

            if (valid_in) begin
                if (pixel_count < KERNEL_SIZE-1)
                    pixel_out <= {OUT_W{1'b0}};
                else
                    pixel_out <= clipped_pixel;

                for (r = 0; r < KERNEL_SIZE; r = r + 1) begin
                    for (c = 0; c < KERNEL_SIZE-1; c = c + 1) begin
                        shift_window[r][c] <= shift_window[r][c+1];
                    end
                end

                for (r = 0; r < KERNEL_SIZE-1; r = r + 1) begin
                    shift_window[r][KERNEL_SIZE-1] <= linebuf[r][col_count];
                end
                shift_window[KERNEL_SIZE-1][KERNEL_SIZE-1] <= pixel_in;

                if (KERNEL_SIZE > 1) begin
                    linebuf[0][col_count] <= pixel_in;
                    for (r = 1; r < KERNEL_SIZE-1; r = r + 1) begin
                        linebuf[r][col_count] <= linebuf[r-1][col_count];
                    end
                end

                col_count   <= next_col;
                pixel_count <= pixel_count + 32'd1;

                if (end_of_line) begin
                    for (r = 0; r < KERNEL_SIZE; r = r + 1) begin
                        for (c = 0; c < KERNEL_SIZE-1; c = c + 1) begin
                            shift_window[r][c] <= {DATA_W{1'b0}};
                        end
                    end
                end
            end
        end
    end

endmodule