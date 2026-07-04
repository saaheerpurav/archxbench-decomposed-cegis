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

    function integer CLOG2;
        input integer value;
        integer i;
        begin
            CLOG2 = 0;
            for (i = value - 1; i > 0; i = i >> 1)
                CLOG2 = CLOG2 + 1;
        end
    endfunction

    localparam KS       = KERNEL_SIZE;
    localparam RADIUS   = KERNEL_SIZE / 2;
    localparam OUT_W    = DATA_W + GAIN_W;
    localparam ACC_W    = DATA_W + GAIN_W + CLOG2(KERNEL_SIZE*KERNEL_SIZE);
    localparam COL_W    = CLOG2(IMG_WIDTH);
    localparam ROW_W    = 32;
    localparam WIN_ELEMS = KERNEL_SIZE*KERNEL_SIZE;

    reg [DATA_W-1:0] linebuf [0:KERNEL_SIZE-2][0:IMG_WIDTH-1];
    reg [DATA_W-1:0] window  [0:WIN_ELEMS-1];

    reg [COL_W-1:0] col_cnt;
    reg [ROW_W-1:0] row_cnt;

    wire [COL_W-1:0] next_col;
    wire             end_of_line;

    wire [DATA_W*WIN_ELEMS-1:0] window_flat;
    wire [ACC_W-1:0]            conv_sum;
    wire [OUT_W-1:0]            rounded_sum;
    wire                        window_valid;

    reg [DATA_W-1:0] taps [0:KERNEL_SIZE-1];

    integer r, c, i;

    conv2d_addr_gen #(
        .IMG_WIDTH(IMG_WIDTH)
    ) u_addr_gen (
        .col_in(col_cnt),
        .next_col(next_col),
        .end_of_line(end_of_line)
    );

    conv2d_window_valid #(
        .KERNEL_SIZE(KERNEL_SIZE)
    ) u_window_valid (
        .row_count(row_cnt),
        .col_count(col_cnt),
        .valid_in(valid_in),
        .window_valid(window_valid)
    );

    genvar gi;
    generate
        for (gi = 0; gi < WIN_ELEMS; gi = gi + 1) begin : G_FLATTEN
            assign window_flat[(gi+1)*DATA_W-1:gi*DATA_W] = window[gi];
        end
    endgenerate

    conv2d_dot_product #(
        .DATA_W(DATA_W),
        .KERNEL_SIZE(KERNEL_SIZE),
        .GAIN_W(GAIN_W),
        .ACC_W(ACC_W)
    ) u_dot_product (
        .window_flat(window_flat),
        .sum(conv_sum)
    );

    conv2d_round_clip #(
        .IN_W(ACC_W),
        .OUT_W(OUT_W)
    ) u_round_clip (
        .value_in(conv_sum),
        .value_out(rounded_sum)
    );

    always @(posedge clk) begin
        if (rst) begin
            valid_out <= 1'b0;
            pixel_out <= {OUT_W{1'b0}};
            col_cnt <= {COL_W{1'b0}};
            row_cnt <= {ROW_W{1'b0}};

            for (r = 0; r < KERNEL_SIZE-1; r = r + 1) begin
                for (c = 0; c < IMG_WIDTH; c = c + 1) begin
                    linebuf[r][c] <= {DATA_W{1'b0}};
                end
            end

            for (i = 0; i < WIN_ELEMS; i = i + 1) begin
                window[i] <= {DATA_W{1'b0}};
            end
        end else begin
            valid_out <= window_valid;
            if (window_valid)
                pixel_out <= rounded_sum;
            else
                pixel_out <= {OUT_W{1'b0}};

            if (valid_in) begin
                taps[0] = pixel_in;
                for (r = 1; r < KERNEL_SIZE; r = r + 1) begin
                    taps[r] = linebuf[r-1][col_cnt];
                end

                linebuf[0][col_cnt] <= pixel_in;
                for (r = 1; r < KERNEL_SIZE-1; r = r + 1) begin
                    linebuf[r][col_cnt] <= taps[r];
                end

                for (r = 0; r < KERNEL_SIZE; r = r + 1) begin
                    for (c = 0; c < KERNEL_SIZE-1; c = c + 1) begin
                        window[r*KERNEL_SIZE+c] <= window[r*KERNEL_SIZE+c+1];
                    end
                    window[r*KERNEL_SIZE+KERNEL_SIZE-1] <= taps[KERNEL_SIZE-1-r];
                end

                if (end_of_line) begin
                    col_cnt <= {COL_W{1'b0}};
                    row_cnt <= row_cnt + 1'b1;
                end else begin
                    col_cnt <= next_col;
                end
            end
        end
    end

endmodule