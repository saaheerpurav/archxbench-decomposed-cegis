`timescale 1ns/1ps

module conv1d #(
    parameter DATA_W      = 8,
    parameter KERNEL_SIZE = 5,
    parameter GAIN_W      = 4
) (
    input                          clk,
    input                          rst,
    input                          valid_in,
    input      [DATA_W-1:0]        data_in,
    output                         valid_out,
    output     [DATA_W+GAIN_W-1:0] data_out
);

    localparam MAC_W = DATA_W + GAIN_W + 3;

    reg [DATA_W-1:0] delay0;
    reg [DATA_W-1:0] delay1;
    reg [DATA_W-1:0] delay2;
    reg [DATA_W-1:0] delay3;

    wire [DATA_W-1:0] tap0;
    wire [DATA_W-1:0] tap1;
    wire [DATA_W-1:0] tap2;
    wire [DATA_W-1:0] tap3;
    wire [DATA_W-1:0] tap4;
    wire [MAC_W-1:0]  mac_sum;

    conv1d_tap_window #(
        .DATA_W(DATA_W)
    ) u_tap_window (
        .data_in(data_in),
        .delay0(delay0),
        .delay1(delay1),
        .delay2(delay2),
        .delay3(delay3),
        .tap0(tap0),
        .tap1(tap1),
        .tap2(tap2),
        .tap3(tap3),
        .tap4(tap4)
    );

    conv1d_mac5 #(
        .DATA_W(DATA_W),
        .GAIN_W(GAIN_W)
    ) u_mac5 (
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

    assign valid_out = valid_in & ~rst;

    always @(posedge clk) begin
        if (rst) begin
            delay0 <= {DATA_W{1'b0}};
            delay1 <= {DATA_W{1'b0}};
            delay2 <= {DATA_W{1'b0}};
            delay3 <= {DATA_W{1'b0}};
        end else if (valid_in) begin
            delay0 <= data_in;
            delay1 <= delay0;
            delay2 <= delay1;
            delay3 <= delay2;
        end
    end

endmodule