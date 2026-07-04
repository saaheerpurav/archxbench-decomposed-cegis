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

    function integer clog2;
        input integer value;
        integer v;
        begin
            v = value - 1;
            for (clog2 = 0; v > 0; clog2 = clog2 + 1)
                v = v >> 1;
        end
    endfunction

    localparam K2      = KERNEL_SIZE * KERNEL_SIZE;
    localparam ACC_W   = DATA_W + GAIN_W + clog2(K2);
    localparam OUT_W   = DATA_W + GAIN_W;
    localparam COL_W   = clog2(IMG_WIDTH);
    localparam ROW_W   = 16;

    reg [DATA_W-1:0] linebuf [0:KERNEL_SIZE-2][0:IMG_WIDTH-1];
    reg [DATA_W-1:0] window  [0:KERNEL_SIZE-1][0:KERNEL_SIZE-1];

    reg [COL_W-1:0] col_count;
    reg [ROW_W-1:0] row_count;

    wire [K2*DATA_W-1:0] window_flat;
    wire [K2*DATA_W-1:0] padded_window_flat;
    wire [K2*GAIN_W-1:0] coeff_flat;
    wire [ACC_W-1:0] mac_result;
    wire [OUT_W-1:0] rounded_result;

    wire window_ready;
    wire at_left_edge;
    wire at_top_edge;

    integer i, r, c;
    integer idx;
    reg [DATA_W-1:0] cascade;
    reg [DATA_W-1:0] delayed [0:KERNEL_SIZE-2];

    assign at_left_edge = (col_count < KERNEL_SIZE-1);
    assign at_top_edge  = (row_count < KERNEL_SIZE-1);
    assign window_ready = valid_in && !at_left_edge && !at_top_edge;

    genvar gr, gc;
    generate
        for (gr = 0; gr < KERNEL_SIZE; gr = gr + 1) begin : GEN_WIN_R
            for (gc = 0; gc < KERNEL_SIZE; gc = gc + 1) begin : GEN_WIN_C
                assign window_flat[((gr*KERNEL_SIZE+gc+1)*DATA_W)-1:
                                   ((gr*KERNEL_SIZE+gc)*DATA_W)] = window[gr][gc];
            end
        end
    endgenerate

    conv2d_coeff_rom #(
        .KERNEL_SIZE(KERNEL_SIZE),
        .COEFF_W(GAIN_W)
    ) u_coeff_rom (
        .coeffs(coeff_flat)
    );

    conv2d_window_pad #(
        .DATA_W(DATA_W),
        .KERNEL_SIZE(KERNEL_SIZE)
    ) u_window_pad (
        .window_in(window_flat),
        .pad_top(at_top_edge),
        .pad_left(at_left_edge),
        .window_out(padded_window_flat)
    );

    conv2d_dot_product #(
        .DATA_W(DATA_W),
        .COEFF_W(GAIN_W),
        .KERNEL_SIZE(KERNEL_SIZE),
        .ACC_W(ACC_W)
    ) u_dot_product (
        .pixels(padded_window_flat),
        .coeffs(coeff_flat),
        .acc(mac_result)
    );

    conv2d_output_cast #(
        .IN_W(ACC_W),
        .OUT_W(OUT_W)
    ) u_output_cast (
        .acc_in(mac_result),
        .pixel_out(rounded_result)
    );

    always @(posedge clk) begin
        if (rst) begin
            valid_out <= 1'b0;
            pixel_out <= {OUT_W{1'b0}};
            col_count <= {COL_W{1'b0}};
            row_count <= {ROW_W{1'b0}};

            for (r = 0; r < KERNEL_SIZE-1; r = r + 1)
                for (c = 0; c < IMG_WIDTH; c = c + 1)
                    linebuf[r][c] <= {DATA_W{1'b0}};

            for (r = 0; r < KERNEL_SIZE; r = r + 1)
                for (c = 0; c < KERNEL_SIZE; c = c + 1)
                    window[r][c] <= {DATA_W{1'b0}};
        end else begin
            valid_out <= window_ready;
            if (window_ready)
                pixel_out <= rounded_result;
            else
                pixel_out <= {OUT_W{1'b0}};

            if (valid_in) begin
                cascade = pixel_in;
                for (r = 0; r < KERNEL_SIZE-1; r = r + 1) begin
                    delayed[r] = linebuf[r][col_count];
                    linebuf[r][col_count] <= cascade;
                    cascade = delayed[r];
                end

                for (r = 0; r < KERNEL_SIZE; r = r + 1) begin
                    for (c = KERNEL_SIZE-1; c > 0; c = c - 1)
                        window[r][c] <= window[r][c-1];

                    if (r == 0)
                        window[r][0] <= pixel_in;
                    else
                        window[r][0] <= delayed[r-1];
                end

                if (col_count == IMG_WIDTH-1) begin
                    col_count <= {COL_W{1'b0}};
                    row_count <= row_count + 1'b1;
                end else begin
                    col_count <= col_count + 1'b1;
                end
            end
        end
    end

endmodule