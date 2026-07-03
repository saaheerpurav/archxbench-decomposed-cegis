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
    output reg                      valid_out,
    output reg [DATA_W+GAIN_W-1:0]  data_out
);

    localparam OUT_W = DATA_W + GAIN_W;
    localparam COEFF_W = 8;
    localparam ACC_W = DATA_W + COEFF_W + 4;

    reg  [DATA_W*KERNEL_SIZE-1:0] window_reg;
    wire [DATA_W*KERNEL_SIZE-1:0] window_next;
    wire [COEFF_W*KERNEL_SIZE-1:0] coeffs_flat;
    wire [ACC_W-1:0] mac_sum;
    wire [OUT_W-1:0] scaled_sum;

    conv1d_window_next #(
        .DATA_W(DATA_W),
        .KERNEL_SIZE(KERNEL_SIZE)
    ) u_window_next (
        .window_in(window_reg),
        .sample_in(data_in),
        .window_out(window_next)
    );

    conv1d_coeff_rom #(
        .KERNEL_SIZE(KERNEL_SIZE),
        .COEFF_W(COEFF_W)
    ) u_coeff_rom (
        .coeffs_flat(coeffs_flat)
    );

    conv1d_mac #(
        .DATA_W(DATA_W),
        .KERNEL_SIZE(KERNEL_SIZE),
        .COEFF_W(COEFF_W),
        .ACC_W(ACC_W)
    ) u_mac (
        .window_flat(window_next),
        .coeffs_flat(coeffs_flat),
        .sum(mac_sum)
    );

    conv1d_scale #(
        .ACC_W(ACC_W),
        .OUT_W(OUT_W),
        .SHIFT(4)
    ) u_scale (
        .sum_in(mac_sum),
        .data_out(scaled_sum)
    );

    always @(posedge clk) begin
        if (rst) begin
            window_reg <= {DATA_W*KERNEL_SIZE{1'b0}};
            valid_out  <= 1'b0;
            data_out   <= {OUT_W{1'b0}};
        end else begin
            valid_out <= valid_in;

            if (valid_in) begin
                window_reg <= window_next;
                data_out   <= scaled_sum;
            end
        end
    end

endmodule