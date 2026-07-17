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

    function integer clog2;
        input integer value;
        integer v;
        begin
            v = value - 1;
            clog2 = 0;
            while (v > 0) begin
                v = v >> 1;
                clog2 = clog2 + 1;
            end
        end
    endfunction

    localparam MAC_W = DATA_W + GAIN_W + clog2(KERNEL_SIZE);

    reg [DATA_W-1:0] tap1;
    reg [DATA_W-1:0] tap2;
    reg [DATA_W-1:0] tap3;
    reg [DATA_W-1:0] tap4;

    wire [DATA_W-1:0] next_tap1;
    wire [DATA_W-1:0] next_tap2;
    wire [DATA_W-1:0] next_tap3;
    wire [DATA_W-1:0] next_tap4;

    wire [MAC_W-1:0] mac_sum;

    assign valid_out = valid_in;

    conv1d_tap_shift #(
        .DATA_W(DATA_W)
    ) u_tap_shift (
        .sample_in(data_in),
        .tap1_in(tap1),
        .tap2_in(tap2),
        .tap3_in(tap3),
        .tap1_out(next_tap1),
        .tap2_out(next_tap2),
        .tap3_out(next_tap3),
        .tap4_out(next_tap4)
    );

    conv1d_mac5 #(
        .DATA_W(DATA_W),
        .MAC_W(MAC_W)
    ) u_mac5 (
        .x0(data_in),
        .x1(tap1),
        .x2(tap2),
        .x3(tap3),
        .x4(tap4),
        .mac_out(mac_sum)
    );

    conv1d_gain_shift #(
        .MAC_W(MAC_W),
        .OUT_W(DATA_W+GAIN_W),
        .GAIN_W(GAIN_W)
    ) u_gain_shift (
        .mac_in(mac_sum),
        .data_out(data_out)
    );

    always @(posedge clk) begin
        if (rst) begin
            tap1 <= {DATA_W{1'b0}};
            tap2 <= {DATA_W{1'b0}};
            tap3 <= {DATA_W{1'b0}};
            tap4 <= {DATA_W{1'b0}};
        end else if (valid_in) begin
            tap1 <= next_tap1;
            tap2 <= next_tap2;
            tap3 <= next_tap3;
            tap4 <= next_tap4;
        end
    end

endmodule