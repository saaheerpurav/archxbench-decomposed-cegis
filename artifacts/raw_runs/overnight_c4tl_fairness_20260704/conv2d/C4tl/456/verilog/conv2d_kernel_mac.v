`timescale 1ns/1ps

module conv2d_kernel_mac #(
    parameter DATA_W      = 8,
    parameter IMG_WIDTH   = 64,
    parameter KERNEL_SIZE = 3,
    parameter GAIN_W      = 4,
    parameter ACC_W       = DATA_W + GAIN_W + 8
) (
    input      [31:0]         center_row,
    input      [31:0]         center_col,
    input      [DATA_W-1:0]   p00,
    input      [DATA_W-1:0]   p01,
    input      [DATA_W-1:0]   p02,
    input      [DATA_W-1:0]   p10,
    input      [DATA_W-1:0]   p11,
    input      [DATA_W-1:0]   p12,
    input      [DATA_W-1:0]   p20,
    input      [DATA_W-1:0]   p21,
    input      [DATA_W-1:0]   p22,
    output     [ACC_W-1:0]    sum
);
    wire [ACC_W-1:0] s3;

    conv2d_window_select #(
        .DATA_W(DATA_W),
        .ACC_W(ACC_W)
    ) u_window_select (
        .p00(p00), .p01(p01), .p02(p02),
        .p10(p10), .p11(p11), .p12(p12),
        .p20(p20), .p21(p21), .p22(p22),
        .weighted_sum(s3)
    );

    assign sum = (KERNEL_SIZE == 3) ? s3 : {ACC_W{1'b0}};

endmodule