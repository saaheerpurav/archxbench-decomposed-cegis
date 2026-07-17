`timescale 1ns/1ps

module conv2d #(
    parameter DATA_W      = 8,
    parameter IMG_WIDTH   = 64,
    parameter KERNEL_SIZE = 3,
    parameter GAIN_W      = 4
) (
    input                            clk,
    input                            rst,
    input                            valid_in,
    input      [DATA_W-1:0]          pixel_in,
    output reg                       valid_out,
    output reg [DATA_W+GAIN_W-1:0]   pixel_out
);

    localparam OUT_W = DATA_W + GAIN_W;
    localparam ACC_W = DATA_W + GAIN_W + 8;
    localparam TAP_COUNT = KERNEL_SIZE * KERNEL_SIZE;

    integer i, r, c;
    integer row_idx;
    integer col_idx;

    reg [DATA_W-1:0] linebuf [0:(KERNEL_SIZE-1)*IMG_WIDTH-1];
    reg [DATA_W-1:0] row_tap [0:KERNEL_SIZE-1];
    reg [DATA_W-1:0] shift_reg [0:TAP_COUNT-1];

    reg [31:0] row_count;
    reg [31:0] col_count;

    wire [TAP_COUNT*DATA_W-1:0] window_bus;
    wire signed [ACC_W-1:0] mac_sum;
    wire window_valid;

    genvar gi;
    generate
        for (gi = 0; gi < TAP_COUNT; gi = gi + 1) begin : PACK_WINDOW
            assign window_bus[gi*DATA_W +: DATA_W] = shift_reg[gi];
        end
    endgenerate

    conv2d_valid_region #(
        .IMG_WIDTH(IMG_WIDTH),
        .KERNEL_SIZE(KERNEL_SIZE)
    ) u_valid_region (
        .valid_in(valid_in),
        .row_count(row_count),
        .col_count(col_count),
        .window_valid(window_valid)
    );

    conv2d_mac #(
        .DATA_W(DATA_W),
        .KERNEL_SIZE(KERNEL_SIZE),
        .GAIN_W(GAIN_W),
        .ACC_W(ACC_W)
    ) u_mac (
        .window(window_bus),
        .sum(mac_sum)
    );

    always @(posedge clk) begin
        if (rst) begin
            valid_out <= 1'b0;
            pixel_out <= {OUT_W{1'b0}};
            row_count <= 32'd0;
            col_count <= 32'd0;

            for (i = 0; i < (KERNEL_SIZE-1)*IMG_WIDTH; i = i + 1)
                linebuf[i] <= {DATA_W{1'b0}};

            for (i = 0; i < TAP_COUNT; i = i + 1)
                shift_reg[i] <= {DATA_W{1'b0}};
        end else begin
            valid_out <= 1'b0;

            if (valid_in) begin
                row_tap[KERNEL_SIZE-1] = pixel_in;

                for (r = KERNEL_SIZE-2; r >= 0; r = r - 1)
                    row_tap[r] = linebuf[r*IMG_WIDTH + col_count];

                linebuf[col_count] <= pixel_in;
                for (r = 1; r < KERNEL_SIZE-1; r = r + 1)
                    linebuf[r*IMG_WIDTH + col_count] <= linebuf[(r-1)*IMG_WIDTH + col_count];

                for (r = 0; r < KERNEL_SIZE; r = r + 1) begin
                    for (c = 0; c < KERNEL_SIZE-1; c = c + 1) begin
                        shift_reg[r*KERNEL_SIZE + c] <= shift_reg[r*KERNEL_SIZE + c + 1];
                    end

                    if ((row_count < KERNEL_SIZE-1-r) || (col_count < KERNEL_SIZE-1))
                        shift_reg[r*KERNEL_SIZE + KERNEL_SIZE-1] <= {DATA_W{1'b0}};
                    else
                        shift_reg[r*KERNEL_SIZE + KERNEL_SIZE-1] <= row_tap[r];
                end

                valid_out <= window_valid;
                if (window_valid) begin
                    if (mac_sum < 0)
                        pixel_out <= {OUT_W{1'b0}};
                    else
                        pixel_out <= mac_sum[OUT_W-1:0];
                end else begin
                    pixel_out <= {OUT_W{1'b0}};
                end

                if (col_count == IMG_WIDTH-1) begin
                    col_count <= 32'd0;
                    row_count <= row_count + 32'd1;
                end else begin
                    col_count <= col_count + 32'd1;
                end
            end
        end
    end

endmodule