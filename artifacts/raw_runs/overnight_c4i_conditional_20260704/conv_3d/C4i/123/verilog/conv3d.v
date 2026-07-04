`timescale 1ns/1ps

module conv3d #(
    parameter K1 = 3,
    parameter K2 = 3,
    parameter K3 = 3,
    parameter D = 8,
    parameter H = 64,
    parameter W = 64,
    parameter DATA_W = 8,
    parameter LOG_KW = 4
) (
    input clk,
    input rst,
    input [DATA_W-1:0] voxel_in,
    input valid_in,
    input [K1*K2*K3*DATA_W-1:0] kernel,
    input last_in,
    output [DATA_W+LOG_KW-1:0] voxel_out,
    output valid_out,
    output done
);

    localparam KW = K1*K2*K3;
    localparam OUT_W = DATA_W + LOG_KW;
    localparam COUNT_W = 32;
    localparam ACC_W = (2*DATA_W) + LOG_KW + 8;

    reg [COUNT_W-1:0] sample_count;
    reg [KW*DATA_W-1:0] window_reg;
    reg [OUT_W-1:0] voxel_out_reg;
    reg valid_out_reg;
    reg done_reg;

    wire [KW*DATA_W-1:0] next_window;
    wire window_valid_now;
    wire input_done_now;
    wire [ACC_W-1:0] mac_sum;
    wire [OUT_W-1:0] clipped_sum;

    conv3d_window_shift #(
        .K1(K1),
        .K2(K2),
        .K3(K3),
        .DATA_W(DATA_W)
    ) u_window_shift (
        .window_in(window_reg),
        .voxel_in(voxel_in),
        .window_out(next_window)
    );

    conv3d_window_valid #(
        .K1(K1),
        .K2(K2),
        .K3(K3),
        .D(D),
        .H(H),
        .W(W)
    ) u_window_valid (
        .sample_count(sample_count),
        .valid_in(valid_in),
        .last_in(last_in),
        .window_valid(window_valid_now),
        .done(input_done_now)
    );

    conv3d_mac #(
        .K1(K1),
        .K2(K2),
        .K3(K3),
        .DATA_W(DATA_W),
        .LOG_KW(LOG_KW),
        .ACC_W(ACC_W)
    ) u_mac (
        .window(next_window),
        .kernel(kernel),
        .sum(mac_sum)
    );

    conv3d_output_cast #(
        .IN_W(ACC_W),
        .OUT_W(OUT_W)
    ) u_output_cast (
        .sum_in(mac_sum),
        .voxel_out(clipped_sum)
    );

    always @(posedge clk) begin
        if (rst) begin
            sample_count  <= {COUNT_W{1'b0}};
            window_reg    <= {(KW*DATA_W){1'b0}};
            voxel_out_reg <= {OUT_W{1'b0}};
            valid_out_reg <= 1'b0;
            done_reg      <= 1'b0;
        end else begin
            done_reg <= 1'b0;

            if (valid_in) begin
                window_reg    <= next_window;
                sample_count  <= sample_count + {{(COUNT_W-1){1'b0}}, 1'b1};
                voxel_out_reg <= clipped_sum;
                valid_out_reg <= window_valid_now;
                done_reg      <= input_done_now;
            end else begin
                valid_out_reg <= 1'b0;
            end
        end
    end

    assign voxel_out = voxel_out_reg;
    assign valid_out = valid_out_reg;
    assign done = done_reg;

endmodule