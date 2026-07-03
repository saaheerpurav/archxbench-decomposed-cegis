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

    reg [DATA_W-1:0] tap1;
    reg [DATA_W-1:0] tap2;
    reg [DATA_W-1:0] tap3;
    reg [DATA_W-1:0] tap4;

    wire [DATA_W-1:0] win0;
    wire [DATA_W-1:0] win1;
    wire [DATA_W-1:0] win2;
    wire [DATA_W-1:0] win3;
    wire [DATA_W-1:0] win4;
    wire [MAC_W-1:0]  mac_sum;

    conv1d_window #(
        .DATA_W(DATA_W)
    ) u_window (
        .data_in(data_in),
        .tap1(tap1),
        .tap2(tap2),
        .tap3(tap3),
        .tap4(tap4),
        .win0(win0),
        .win1(win1),
        .win2(win2),
        .win3(win3),
        .win4(win4)
    );

    conv1d_mac #(
        .DATA_W(DATA_W),
        .GAIN_W(GAIN_W)
    ) u_mac (
        .x0(win0),
        .x1(win1),
        .x2(win2),
        .x3(win3),
        .x4(win4),
        .mac_sum(mac_sum)
    );

    conv1d_normalize #(
        .DATA_W(DATA_W),
        .GAIN_W(GAIN_W)
    ) u_normalize (
        .mac_sum(mac_sum),
        .data_out(data_out)
    );

    assign valid_out = valid_in;

    always @(posedge clk) begin
        if (rst) begin
            tap1 <= {DATA_W{1'b0}};
            tap2 <= {DATA_W{1'b0}};
            tap3 <= {DATA_W{1'b0}};
            tap4 <= {DATA_W{1'b0}};
        end else if (valid_in) begin
            tap1 <= data_in;
            tap2 <= tap1;
            tap3 <= tap2;
            tap4 <= tap3;
        end
    end

endmodule