`timescale 1ns/1ps

module conv2d_window_builder #(
    parameter DATA_W      = 8,
    parameter IMG_WIDTH   = 64,
    parameter KERNEL_SIZE = 3,
    parameter HIST_N      = 200
) (
    input  [(HIST_N*DATA_W)-1:0]                       history_flat,
    input  [DATA_W-1:0]                                pixel_in,
    input  [31:0]                                      pix_count,
    input                                              valid_in,
    output reg [(KERNEL_SIZE*KERNEL_SIZE*DATA_W)-1:0]  window_flat,
    output reg                                         window_valid
);
    localparam RADIUS = KERNEL_SIZE / 2;
    localparam CENTER_DELAY = (RADIUS * IMG_WIDTH) + RADIUS + 1;

    integer kr;
    integer kc;
    integer idx;

    integer center_abs;
    integer center_row;
    integer center_col;

    integer n_row;
    integer n_col;
    integer n_abs;
    integer age;

    reg [DATA_W-1:0] sample;

    always @(*) begin
        window_flat  = {KERNEL_SIZE*KERNEL_SIZE*DATA_W{1'b0}};
        window_valid = 1'b0;

        if (valid_in) begin
            window_valid = 1'b1;

            center_abs = $signed({1'b0, pix_count}) - CENTER_DELAY;

            if (center_abs >= 0) begin
                center_row = center_abs / IMG_WIDTH;
                center_col = center_abs % IMG_WIDTH;
            end else begin
                center_row = 0;
                center_col = 0;
            end

            for (kr = 0; kr < KERNEL_SIZE; kr = kr + 1) begin
                for (kc = 0; kc < KERNEL_SIZE; kc = kc + 1) begin
                    idx = kr * KERNEL_SIZE + kc;

                    n_row = center_row + kr - RADIUS;
                    n_col = center_col + kc - RADIUS;

                    sample = {DATA_W{1'b0}};

                    if ((center_abs >= 0) &&
                        (n_row >= 0) && (n_row < IMG_WIDTH) &&
                        (n_col >= 0) && (n_col < IMG_WIDTH)) begin

                        n_abs = n_row * IMG_WIDTH + n_col;

                        if (n_abs == pix_count) begin
                            sample = pixel_in;
                        end else if ((n_abs >= 0) && (n_abs < pix_count)) begin
                            age = pix_count - n_abs;

                            if ((age > 0) && (age <= HIST_N)) begin
                                sample = history_flat[((age - 1) * DATA_W) +: DATA_W];
                            end
                        end
                    end

                    window_flat[(idx * DATA_W) +: DATA_W] = sample;
                end
            end
        end
    end

endmodule