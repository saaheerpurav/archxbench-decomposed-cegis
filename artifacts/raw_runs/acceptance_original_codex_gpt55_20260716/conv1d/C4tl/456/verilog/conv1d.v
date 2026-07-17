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

    localparam MAC_W = DATA_W + GAIN_W + 3;

    reg [DATA_W-1:0] x_d1;
    reg [DATA_W-1:0] x_d2;
    reg [DATA_W-1:0] x_d3;
    reg [DATA_W-1:0] x_d4;

    wire [DATA_W*5-1:0] window_flat;
    wire [MAC_W-1:0]    mac_sum;

    assign valid_out = valid_in;

    always @(posedge clk) begin
        if (rst) begin
            x_d1 <= {DATA_W{1'b0}};
            x_d2 <= {DATA_W{1'b0}};
            x_d3 <= {DATA_W{1'b0}};
            x_d4 <= {DATA_W{1'b0}};
        end else if (valid_in) begin
            x_d1 <= data_in;
            x_d2 <= x_d1;
            x_d3 <= x_d2;
            x_d4 <= x_d3;
        end
    end

    conv1d_window #(
        .DATA_W(DATA_W)
    ) u_window (
        .x0(data_in),
        .x1(x_d1),
        .x2(x_d2),
        .x3(x_d3),
        .x4(x_d4),
        .window_flat(window_flat)
    );

    conv1d_mac5 #(
        .DATA_W(DATA_W),
        .GAIN_W(GAIN_W)
    ) u_mac5 (
        .window_flat(window_flat),
        .mac_sum(mac_sum)
    );

    conv1d_normalize #(
        .DATA_W(DATA_W),
        .GAIN_W(GAIN_W),
        .MAC_W(MAC_W)
    ) u_normalize (
        .mac_sum(mac_sum),
        .data_out(data_out)
    );

endmodule