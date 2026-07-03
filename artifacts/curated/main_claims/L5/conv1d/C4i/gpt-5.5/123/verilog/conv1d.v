`timescale 1ns/1ps

module conv1d #(
    parameter DATA_W      = 8,
    parameter KERNEL_SIZE = 5,
    parameter GAIN_W      = 4
) (
    input                       clk,
    input                       rst,
    input                       valid_in,
    input      [DATA_W-1:0]     data_in,
    output                      valid_out,
    output     [DATA_W+GAIN_W-1:0] data_out
);

    localparam MAC_W = DATA_W + GAIN_W + $clog2(KERNEL_SIZE);

    reg [DATA_W-1:0] sample_d1;
    reg [DATA_W-1:0] sample_d2;
    reg [DATA_W-1:0] sample_d3;
    reg [DATA_W-1:0] sample_d4;

    wire [DATA_W-1:0] tap0;
    wire [DATA_W-1:0] tap1;
    wire [DATA_W-1:0] tap2;
    wire [DATA_W-1:0] tap3;
    wire [DATA_W-1:0] tap4;
    wire [MAC_W-1:0]  mac_sum;

    conv1d_window #(
        .DATA_W(DATA_W)
    ) u_window (
        .data_in(data_in),
        .sample_d1(sample_d1),
        .sample_d2(sample_d2),
        .sample_d3(sample_d3),
        .sample_d4(sample_d4),
        .tap0(tap0),
        .tap1(tap1),
        .tap2(tap2),
        .tap3(tap3),
        .tap4(tap4)
    );

    conv1d_mac5 #(
        .DATA_W(DATA_W),
        .KERNEL_SIZE(KERNEL_SIZE),
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
        .KERNEL_SIZE(KERNEL_SIZE),
        .GAIN_W(GAIN_W)
    ) u_normalize (
        .mac_sum(mac_sum),
        .data_out(data_out)
    );

    conv1d_valid_gate u_valid_gate (
        .valid_in(valid_in),
        .valid_out(valid_out)
    );

    always @(posedge clk) begin
        if (rst) begin
            sample_d1 <= {DATA_W{1'b0}};
            sample_d2 <= {DATA_W{1'b0}};
            sample_d3 <= {DATA_W{1'b0}};
            sample_d4 <= {DATA_W{1'b0}};
        end else if (valid_in) begin
            sample_d1 <= data_in;
            sample_d2 <= sample_d1;
            sample_d3 <= sample_d2;
            sample_d4 <= sample_d3;
        end
    end

endmodule