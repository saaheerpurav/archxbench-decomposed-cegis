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
    output                         valid_out,
    output     [DATA_W+GAIN_W-1:0] pixel_out
);

    localparam OUT_W = DATA_W + GAIN_W;
    localparam N_TAPS = KERNEL_SIZE * KERNEL_SIZE;
    localparam ACC_W = OUT_W + 8;

    integer i;
    integer j;

    reg [DATA_W-1:0] line0 [0:IMG_WIDTH-1];
    reg [DATA_W-1:0] line1 [0:IMG_WIDTH-1];

    reg [DATA_W-1:0] row0_c0, row0_c1, row0_c2;
    reg [DATA_W-1:0] row1_c0, row1_c1, row1_c2;
    reg [DATA_W-1:0] row2_c0, row2_c1, row2_c2;

    reg [31:0] col_cnt;
    reg [31:0] row_cnt;
    reg        valid_r;
    reg [OUT_W-1:0] pixel_out_r;

    wire at_left;
    wire at_top;
    wire window_valid;

    wire [DATA_W*N_TAPS-1:0] window_flat;
    wire [8*N_TAPS-1:0]      coeff_flat;
    wire signed [ACC_W-1:0]  mac_sum;
    wire [OUT_W-1:0]         clipped_out;

    conv2d_coord #(
        .IMG_WIDTH(IMG_WIDTH),
        .KERNEL_SIZE(KERNEL_SIZE)
    ) u_coord (
        .row_cnt(row_cnt),
        .col_cnt(col_cnt),
        .valid_in(valid_in),
        .at_left(at_left),
        .at_top(at_top),
        .window_valid(window_valid)
    );

    conv2d_window_pack #(
        .DATA_W(DATA_W),
        .KERNEL_SIZE(KERNEL_SIZE)
    ) u_window_pack (
        .p00(row0_c0), .p01(row0_c1), .p02(row0_c2),
        .p10(row1_c0), .p11(row1_c1), .p12(row1_c2),
        .p20(row2_c0), .p21(row2_c1), .p22(row2_c2),
        .window_flat(window_flat)
    );

    conv2d_coeffs #(
        .KERNEL_SIZE(KERNEL_SIZE)
    ) u_coeffs (
        .coeff_flat(coeff_flat)
    );

    conv2d_dot_product #(
        .DATA_W(DATA_W),
        .KERNEL_SIZE(KERNEL_SIZE),
        .ACC_W(ACC_W)
    ) u_dot_product (
        .window_flat(window_flat),
        .coeff_flat(coeff_flat),
        .sum(mac_sum)
    );

    conv2d_output_cast #(
        .ACC_W(ACC_W),
        .OUT_W(OUT_W)
    ) u_output_cast (
        .sum(mac_sum),
        .pixel_out(clipped_out)
    );

    assign valid_out = valid_r;
    assign pixel_out = pixel_out_r;

    always @(posedge clk) begin
        if (rst) begin
            col_cnt <= 0;
            row_cnt <= 0;
            valid_r <= 1'b0;
            pixel_out_r <= {OUT_W{1'b0}};

            row0_c0 <= 0; row0_c1 <= 0; row0_c2 <= 0;
            row1_c0 <= 0; row1_c1 <= 0; row1_c2 <= 0;
            row2_c0 <= 0; row2_c1 <= 0; row2_c2 <= 0;

            for (i = 0; i < IMG_WIDTH; i = i + 1) begin
                line0[i] <= {DATA_W{1'b0}};
                line1[i] <= {DATA_W{1'b0}};
            end
        end else begin
            valid_r <= 1'b0;

            if (valid_in) begin
                valid_r <= window_valid;
                pixel_out_r <= clipped_out;

                row0_c0 <= row0_c1;
                row0_c1 <= row0_c2;
                row0_c2 <= (row_cnt < 2) ? {DATA_W{1'b0}} : line1[col_cnt];

                row1_c0 <= row1_c1;
                row1_c1 <= row1_c2;
                row1_c2 <= (row_cnt < 1) ? {DATA_W{1'b0}} : line0[col_cnt];

                row2_c0 <= row2_c1;
                row2_c1 <= row2_c2;
                row2_c2 <= pixel_in;

                line1[col_cnt] <= line0[col_cnt];
                line0[col_cnt] <= pixel_in;

                if (col_cnt == IMG_WIDTH-1) begin
                    col_cnt <= 0;
                    row_cnt <= row_cnt + 1;

                    row0_c0 <= 0; row0_c1 <= 0;
                    row1_c0 <= 0; row1_c1 <= 0;
                    row2_c0 <= 0; row2_c1 <= 0;
                end else begin
                    col_cnt <= col_cnt + 1;
                end
            end
        end
    end

endmodule