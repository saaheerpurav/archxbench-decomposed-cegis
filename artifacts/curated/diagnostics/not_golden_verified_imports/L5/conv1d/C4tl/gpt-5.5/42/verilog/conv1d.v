`timescale 1ns/1ps

module conv1d #(
    parameter DATA_W      = 8,
    parameter KERNEL_SIZE = 5,
    parameter GAIN_W      = 4
) (
    input                         clk,
    input                         rst,
    input                         valid_in,
    input      [DATA_W-1:0]       data_in,
    output                        valid_out,
    output     [DATA_W+GAIN_W-1:0] data_out
);

    localparam OUT_W = DATA_W + GAIN_W;

    reg [DATA_W-1:0] sample_shift [0:6];
    reg              valid_r;
    reg [OUT_W-1:0]  data_r;

    wire [4:0] coeff_0;
    wire [4:0] coeff_1;
    wire [4:0] coeff_2;
    wire [4:0] coeff_3;
    wire [4:0] coeff_4;
    wire [4:0] coeff_5;
    wire [4:0] coeff_6;

    wire [DATA_W-1:0] tap_0;
    wire [DATA_W-1:0] tap_1;
    wire [DATA_W-1:0] tap_2;
    wire [DATA_W-1:0] tap_3;
    wire [DATA_W-1:0] tap_4;
    wire [DATA_W-1:0] tap_5;
    wire [DATA_W-1:0] tap_6;

    wire [DATA_W+8:0] mac_sum;
    wire [OUT_W-1:0]  scaled_sum;

    conv1d_coeff_rom #(
        .KERNEL_SIZE(KERNEL_SIZE)
    ) u_coeff_rom (
        .coeff_0(coeff_0),
        .coeff_1(coeff_1),
        .coeff_2(coeff_2),
        .coeff_3(coeff_3),
        .coeff_4(coeff_4),
        .coeff_5(coeff_5),
        .coeff_6(coeff_6)
    );

    conv1d_tap_select #(
        .DATA_W(DATA_W),
        .KERNEL_SIZE(KERNEL_SIZE)
    ) u_tap_select (
        .data_in(data_in),
        .sample_0(sample_shift[0]),
        .sample_1(sample_shift[1]),
        .sample_2(sample_shift[2]),
        .sample_3(sample_shift[3]),
        .sample_4(sample_shift[4]),
        .sample_5(sample_shift[5]),
        .tap_0(tap_0),
        .tap_1(tap_1),
        .tap_2(tap_2),
        .tap_3(tap_3),
        .tap_4(tap_4),
        .tap_5(tap_5),
        .tap_6(tap_6)
    );

    conv1d_mac #(
        .DATA_W(DATA_W)
    ) u_mac (
        .tap_0(tap_0),
        .tap_1(tap_1),
        .tap_2(tap_2),
        .tap_3(tap_3),
        .tap_4(tap_4),
        .tap_5(tap_5),
        .tap_6(tap_6),
        .coeff_0(coeff_0),
        .coeff_1(coeff_1),
        .coeff_2(coeff_2),
        .coeff_3(coeff_3),
        .coeff_4(coeff_4),
        .coeff_5(coeff_5),
        .coeff_6(coeff_6),
        .sum(mac_sum)
    );

    conv1d_scaler #(
        .IN_W(DATA_W+9),
        .OUT_W(OUT_W)
    ) u_scaler (
        .sum_in(mac_sum),
        .data_out(scaled_sum)
    );

    assign valid_out = valid_r;
    assign data_out  = data_r;

    integer i;
    always @(posedge clk) begin
        if (rst) begin
            valid_r <= 1'b0;
            data_r  <= {OUT_W{1'b0}};
            for (i = 0; i < 7; i = i + 1) begin
                sample_shift[i] <= {DATA_W{1'b0}};
            end
        end else begin
            valid_r <= valid_in;
            if (valid_in) begin
                data_r <= scaled_sum;

                sample_shift[0] <= data_in;
                sample_shift[1] <= sample_shift[0];
                sample_shift[2] <= sample_shift[1];
                sample_shift[3] <= sample_shift[2];
                sample_shift[4] <= sample_shift[3];
                sample_shift[5] <= sample_shift[4];
                sample_shift[6] <= sample_shift[5];
            end
        end
    end

endmodule