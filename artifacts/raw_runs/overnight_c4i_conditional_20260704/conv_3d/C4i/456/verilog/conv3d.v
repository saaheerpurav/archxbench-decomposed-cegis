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

    localparam OUT_W = DATA_W + LOG_KW;
    localparam N = D * H * W;
    localparam COUNT_W = 32;
    localparam HIST_W = N * DATA_W;
    localparam MAC_W = (2*DATA_W) + LOG_KW + 4;

    reg [COUNT_W-1:0] voxel_count;
    reg [HIST_W-1:0] volume_history;
    reg [OUT_W-1:0] voxel_out_r;
    reg valid_out_r;
    reg done_r;

    wire [COUNT_W-1:0] x_pos;
    wire [COUNT_W-1:0] y_pos;
    wire [COUNT_W-1:0] z_pos;
    wire input_ready;
    wire window_valid;
    wire [HIST_W-1:0] history_next;
    wire [K1*K2*K3*DATA_W-1:0] window_flat;
    wire [MAC_W-1:0] mac_sum;
    wire [OUT_W-1:0] voxel_truncated;

    assign history_next = {volume_history[HIST_W-DATA_W-1:0], voxel_in};

    conv3d_stream_index #(
        .D(D),
        .H(H),
        .W(W),
        .COUNT_W(COUNT_W)
    ) u_index (
        .linear_index(voxel_count),
        .x_pos(x_pos),
        .y_pos(y_pos),
        .z_pos(z_pos),
        .input_ready(input_ready)
    );

    conv3d_window_extract #(
        .K1(K1),
        .K2(K2),
        .K3(K3),
        .D(D),
        .H(H),
        .W(W),
        .DATA_W(DATA_W),
        .COUNT_W(COUNT_W)
    ) u_window (
        .history(history_next),
        .linear_index(voxel_count),
        .x_pos(x_pos),
        .y_pos(y_pos),
        .z_pos(z_pos),
        .window_flat(window_flat),
        .window_valid(window_valid)
    );

    conv3d_mac #(
        .K1(K1),
        .K2(K2),
        .K3(K3),
        .DATA_W(DATA_W),
        .LOG_KW(LOG_KW),
        .MAC_W(MAC_W)
    ) u_mac (
        .window_flat(window_flat),
        .kernel(kernel),
        .sum(mac_sum)
    );

    conv3d_output_cast #(
        .IN_W(MAC_W),
        .OUT_W(OUT_W)
    ) u_cast (
        .sum_in(mac_sum),
        .voxel_out(voxel_truncated)
    );

    assign voxel_out = voxel_out_r;
    assign valid_out = valid_out_r;
    assign done = done_r;

    always @(posedge clk) begin
        if (rst) begin
            voxel_count <= {COUNT_W{1'b0}};
            volume_history <= {HIST_W{1'b0}};
            voxel_out_r <= {OUT_W{1'b0}};
            valid_out_r <= 1'b0;
            done_r <= 1'b0;
        end else begin
            done_r <= 1'b0;

            if (valid_in && input_ready) begin
                volume_history <= history_next;
                voxel_out_r <= window_valid ? voxel_truncated : {OUT_W{1'b0}};
                valid_out_r <= window_valid;
                done_r <= last_in;

                if (last_in) begin
                    voxel_count <= {COUNT_W{1'b0}};
                end else begin
                    voxel_count <= voxel_count + {{(COUNT_W-1){1'b0}}, 1'b1};
                end
            end else begin
                valid_out_r <= 1'b0;
            end
        end
    end

endmodule