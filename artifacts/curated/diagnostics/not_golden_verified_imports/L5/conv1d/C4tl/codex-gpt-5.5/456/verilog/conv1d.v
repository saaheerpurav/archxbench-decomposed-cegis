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

    localparam OUT_W = DATA_W + GAIN_W;
    localparam ACC_W = DATA_W + GAIN_W + 4;

    reg [DATA_W*KERNEL_SIZE-1:0] window_reg;
    reg                          valid_reg;

    wire [DATA_W*KERNEL_SIZE-1:0] shifted_window;
    wire [KERNEL_SIZE*4-1:0]      coeff_bus;
    wire [ACC_W-1:0]              mac_sum;
    wire [OUT_W-1:0]              scaled_sum;

    conv1d_shift_window #(
        .DATA_W(DATA_W),
        .KERNEL_SIZE(KERNEL_SIZE)
    ) u_shift_window (
        .window_in(window_reg),
        .sample_in(data_in),
        .window_out(shifted_window)
    );

    conv1d_coeff_rom #(
        .KERNEL_SIZE(KERNEL_SIZE)
    ) u_coeff_rom (
        .coeffs(coeff_bus)
    );

    conv1d_mac #(
        .DATA_W(DATA_W),
        .KERNEL_SIZE(KERNEL_SIZE),
        .COEFF_W(4),
        .ACC_W(ACC_W)
    ) u_mac (
        .window(window_reg),
        .coeffs(coeff_bus),
        .sum(mac_sum)
    );

    conv1d_output_scale #(
        .ACC_W(ACC_W),
        .OUT_W(OUT_W),
        .SHIFT(4)
    ) u_output_scale (
        .sum_in(mac_sum),
        .data_out(scaled_sum)
    );

    assign valid_out = valid_reg;
    assign data_out  = scaled_sum;

    always @(posedge clk) begin
        if (rst) begin
            window_reg <= {DATA_W*KERNEL_SIZE{1'b0}};
            valid_reg  <= 1'b0;
        end else begin
            valid_reg <= valid_in;
            if (valid_in) begin
                window_reg <= shifted_window;
            end
        end
    end

endmodule