`timescale 1ns/1ps

module conv1d #(
    parameter DATA_W      = 8,
    parameter KERNEL_SIZE = 5,
    parameter GAIN_W      = 4
) (
    input                           clk,
    input                           rst,
    input                           valid_in,
    input      [DATA_W-1:0]         data_in,
    output                          valid_out,
    output     [DATA_W+GAIN_W-1:0]  data_out
);

    localparam ACC_W = DATA_W + GAIN_W + 3;

    reg [DATA_W-1:0] delay_1;
    reg [DATA_W-1:0] delay_2;
    reg [DATA_W-1:0] delay_3;
    reg [DATA_W-1:0] delay_4;

    wire [DATA_W-1:0] tap0;
    wire [DATA_W-1:0] tap1;
    wire [DATA_W-1:0] tap2;
    wire [DATA_W-1:0] tap3;
    wire [DATA_W-1:0] tap4;
    wire [ACC_W-1:0]  mac_sum;

    conv1d_window #(
        .DATA_W(DATA_W)
    ) u_window (
        .data_in(data_in),
        .delay_1(delay_1),
        .delay_2(delay_2),
        .delay_3(delay_3),
        .delay_4(delay_4),
        .tap0(tap0),
        .tap1(tap1),
        .tap2(tap2),
        .tap3(tap3),
        .tap4(tap4)
    );

    conv1d_kernel_mac #(
        .DATA_W(DATA_W),
        .GAIN_W(GAIN_W)
    ) u_kernel_mac (
        .tap0(tap0),
        .tap1(tap1),
        .tap2(tap2),
        .tap3(tap3),
        .tap4(tap4),
        .mac_sum(mac_sum)
    );

    conv1d_normalize #(
        .DATA_W(DATA_W),
        .GAIN_W(GAIN_W)
    ) u_normalize (
        .mac_sum(mac_sum),
        .data_out(data_out)
    );

    conv1d_valid #(
        .DATA_W(DATA_W)
    ) u_valid (
        .valid_in(valid_in),
        .valid_out(valid_out)
    );

    always @(posedge clk) begin
        if (rst) begin
            delay_1 <= {DATA_W{1'b0}};
            delay_2 <= {DATA_W{1'b0}};
            delay_3 <= {DATA_W{1'b0}};
            delay_4 <= {DATA_W{1'b0}};
        end else if (valid_in) begin
            delay_1 <= data_in;
            delay_2 <= delay_1;
            delay_3 <= delay_2;
            delay_4 <= delay_3;
        end
    end

endmodule