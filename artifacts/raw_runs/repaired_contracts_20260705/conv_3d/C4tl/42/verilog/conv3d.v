`timescale 1ns/1ps

module conv3d #(
    parameter K1 = 3,
    parameter K2 = 3,
    parameter K3 = 3,
    parameter D = 8,
    parameter H = 64,
    parameter W = 64,
    parameter DATA_W = 8,
    parameter LOG_KW = 5
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

    localparam N = D * H * W;
    localparam WIN_SIZE = K1 * K2 * K3;
    localparam OUT_W = DATA_W + LOG_KW;
    localparam COUNT_W = clog2(N + 1);
    localparam X_W = clog2(W);
    localparam Y_W = clog2(H);
    localparam Z_W = clog2(D);

    function integer clog2;
        input integer value;
        integer i;
        begin
            value = value - 1;
            for (i = 0; value > 0; i = i + 1)
                value = value >> 1;
            clog2 = (i == 0) ? 1 : i;
        end
    endfunction

    reg [N*DATA_W-1:0] volume_flat;
    reg [COUNT_W-1:0] in_count;

    wire [X_W-1:0] x_pos;
    wire [Y_W-1:0] y_pos;
    wire [Z_W-1:0] z_pos;
    wire window_ok;
    wire [WIN_SIZE*DATA_W-1:0] window_flat;
    wire [OUT_W-1:0] mac_sum;

    reg [OUT_W-1:0] voxel_out_r;
    reg valid_out_r;
    reg done_r;

    assign voxel_out = voxel_out_r;
    assign valid_out = valid_out_r;
    assign done = done_r;

    conv3d_stream_indexer #(
        .D(D), .H(H), .W(W)
    ) u_indexer (
        .linear_idx(in_count),
        .x_pos(x_pos),
        .y_pos(y_pos),
        .z_pos(z_pos)
    );

    conv3d_window_valid #(
        .K1(K1), .K2(K2), .K3(K3),
        .D(D), .H(H), .W(W)
    ) u_window_valid (
        .x_pos(x_pos),
        .y_pos(y_pos),
        .z_pos(z_pos),
        .valid_window(window_ok)
    );

    conv3d_window_reader #(
        .K1(K1), .K2(K2), .K3(K3),
        .D(D), .H(H), .W(W),
        .DATA_W(DATA_W)
    ) u_window_reader (
        .volume_flat(volume_flat),
        .current_idx(in_count),
        .current_voxel(voxel_in),
        .x_pos(x_pos),
        .y_pos(y_pos),
        .z_pos(z_pos),
        .window_flat(window_flat)
    );

    conv3d_mac_tree #(
        .K1(K1), .K2(K2), .K3(K3),
        .DATA_W(DATA_W),
        .OUT_W(OUT_W)
    ) u_mac_tree (
        .window_flat(window_flat),
        .kernel(kernel),
        .sum_out(mac_sum)
    );

    always @(posedge clk) begin
        if (rst) begin
            volume_flat <= {N*DATA_W{1'b0}};
            in_count <= {COUNT_W{1'b0}};
            voxel_out_r <= {OUT_W{1'b0}};
            valid_out_r <= 1'b0;
            done_r <= 1'b0;
        end else begin
            valid_out_r <= 1'b0;
            done_r <= 1'b0;

            if (valid_in) begin
                volume_flat[in_count*DATA_W +: DATA_W] <= voxel_in;
                voxel_out_r <= mac_sum;
                valid_out_r <= window_ok;
                done_r <= last_in;

                if (last_in)
                    in_count <= {COUNT_W{1'b0}};
                else if (in_count != N[COUNT_W-1:0] - 1'b1)
                    in_count <= in_count + 1'b1;
            end
        end
    end

endmodule