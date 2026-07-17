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
    localparam K2    = KERNEL_SIZE * KERNEL_SIZE;

    integer i;
    integer r;
    integer c;

    reg [15:0] col_count;
    reg [15:0] row_count;

    reg [DATA_W-1:0] line0 [0:IMG_WIDTH-1];
    reg [DATA_W-1:0] line1 [0:IMG_WIDTH-1];
    reg [DATA_W-1:0] line2 [0:IMG_WIDTH-1];
    reg [DATA_W-1:0] line3 [0:IMG_WIDTH-1];
    reg [DATA_W-1:0] line4 [0:IMG_WIDTH-1];
    reg [DATA_W-1:0] line5 [0:IMG_WIDTH-1];

    reg [DATA_W-1:0] window [0:48];

    reg [DATA_W*K2-1:0] window_flat;
    wire [ACC_W-1:0] mac_result;
    wire [OUT_W-1:0] clipped_result;
    wire window_ready;

    conv2d_window_valid #(
        .IMG_WIDTH(IMG_WIDTH),
        .KERNEL_SIZE(KERNEL_SIZE)
    ) u_window_valid (
        .row(row_count),
        .col(col_count),
        .valid_in(valid_in),
        .valid_out(window_ready)
    );

    conv2d_mac #(
        .DATA_W(DATA_W),
        .KERNEL_SIZE(KERNEL_SIZE),
        .GAIN_W(GAIN_W),
        .ACC_W(ACC_W)
    ) u_mac (
        .window_flat(window_flat),
        .mac_out(mac_result)
    );

    conv2d_saturate #(
        .IN_W(ACC_W),
        .OUT_W(OUT_W)
    ) u_saturate (
        .value_in(mac_result),
        .value_out(clipped_result)
    );

    always @* begin
        window_flat = {DATA_W*K2{1'b0}};
        for (i = 0; i < K2; i = i + 1) begin
            window_flat[i*DATA_W +: DATA_W] = window[i];
        end
    end

    always @(posedge clk) begin
        if (rst) begin
            col_count <= 16'd0;
            row_count <= 16'd0;
            valid_out <= 1'b0;
            pixel_out <= {OUT_W{1'b0}};

            for (i = 0; i < 49; i = i + 1) begin
                window[i] <= {DATA_W{1'b0}};
            end

            for (i = 0; i < IMG_WIDTH; i = i + 1) begin
                line0[i] <= {DATA_W{1'b0}};
                line1[i] <= {DATA_W{1'b0}};
                line2[i] <= {DATA_W{1'b0}};
                line3[i] <= {DATA_W{1'b0}};
                line4[i] <= {DATA_W{1'b0}};
                line5[i] <= {DATA_W{1'b0}};
            end
        end else begin
            valid_out <= 1'b0;

            if (valid_in) begin
                pixel_out <= clipped_result;
                valid_out <= window_ready;

                for (r = 0; r < KERNEL_SIZE; r = r + 1) begin
                    for (c = 0; c < KERNEL_SIZE-1; c = c + 1) begin
                        window[r*KERNEL_SIZE+c] <= window[r*KERNEL_SIZE+c+1];
                    end
                end

                if (KERNEL_SIZE >= 1) window[0*KERNEL_SIZE + KERNEL_SIZE-1] <= pixel_in;
                if (KERNEL_SIZE >= 2) window[1*KERNEL_SIZE + KERNEL_SIZE-1] <= line0[col_count];
                if (KERNEL_SIZE >= 3) window[2*KERNEL_SIZE + KERNEL_SIZE-1] <= line1[col_count];
                if (KERNEL_SIZE >= 4) window[3*KERNEL_SIZE + KERNEL_SIZE-1] <= line2[col_count];
                if (KERNEL_SIZE >= 5) window[4*KERNEL_SIZE + KERNEL_SIZE-1] <= line3[col_count];
                if (KERNEL_SIZE >= 6) window[5*KERNEL_SIZE + KERNEL_SIZE-1] <= line4[col_count];
                if (KERNEL_SIZE >= 7) window[6*KERNEL_SIZE + KERNEL_SIZE-1] <= line5[col_count];

                line0[col_count] <= pixel_in;
                line1[col_count] <= line0[col_count];
                line2[col_count] <= line1[col_count];
                line3[col_count] <= line2[col_count];
                line4[col_count] <= line3[col_count];
                line5[col_count] <= line4[col_count];

                if (col_count == IMG_WIDTH-1) begin
                    col_count <= 16'd0;
                    row_count <= row_count + 16'd1;
                end else begin
                    col_count <= col_count + 16'd1;
                end
            end
        end
    end

endmodule