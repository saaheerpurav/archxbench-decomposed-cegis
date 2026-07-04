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

    localparam N = D * H * W;
    localparam KW = K1 * K2 * K3;
    localparam OUT_W = DATA_W + LOG_KW;
    localparam ACC_W = (2 * DATA_W) + LOG_KW + 4;

    reg [31:0] sample_count;
    reg [N*DATA_W-1:0] volume_flat;
    reg [OUT_W-1:0] voxel_out_r;
    reg valid_out_r;
    reg done_r;

    wire [31:0] z_pos;
    wire [31:0] y_pos;
    wire [31:0] x_pos;
    wire window_valid;
    wire [KW*DATA_W-1:0] window_flat;
    wire [ACC_W-1:0] mac_sum;
    wire [OUT_W-1:0] mac_trunc;

    assign voxel_out = voxel_out_r;
    assign valid_out = valid_out_r;
    assign done = done_r;

    conv3d_coord #(
        .D(D),
        .H(H),
        .W(W)
    ) u_coord (
        .index(sample_count),
        .z(z_pos),
        .y(y_pos),
        .x(x_pos)
    );

    conv3d_window_valid #(
        .K1(K1),
        .K2(K2),
        .K3(K3),
        .D(D),
        .H(H),
        .W(W)
    ) u_window_valid (
        .z(z_pos),
        .y(y_pos),
        .x(x_pos),
        .valid(window_valid)
    );

    conv3d_window_gen #(
        .K1(K1),
        .K2(K2),
        .K3(K3),
        .D(D),
        .H(H),
        .W(W),
        .DATA_W(DATA_W)
    ) u_window_gen (
        .volume_flat(volume_flat),
        .voxel_in(voxel_in),
        .current_index(sample_count),
        .valid_in(valid_in),
        .window_flat(window_flat)
    );

    conv3d_mac #(
        .K1(K1),
        .K2(K2),
        .K3(K3),
        .DATA_W(DATA_W),
        .LOG_KW(LOG_KW),
        .ACC_W(ACC_W)
    ) u_mac (
        .window_flat(window_flat),
        .kernel(kernel),
        .sum(mac_sum)
    );

    conv3d_output_clip #(
        .IN_W(ACC_W),
        .OUT_W(OUT_W)
    ) u_output_clip (
        .sum_in(mac_sum),
        .data_out(mac_trunc)
    );

    always @(posedge clk) begin
        if (rst) begin
            sample_count <= 0;
            volume_flat <= 0;
            voxel_out_r <= 0;
            valid_out_r <= 0;
            done_r <= 0;
        end else begin
            done_r <= 0;

            if (valid_in) begin
                volume_flat[sample_count*DATA_W +: DATA_W] <= voxel_in;
                voxel_out_r <= window_valid ? mac_trunc : {OUT_W{1'b0}};
                valid_out_r <= window_valid;

                if (last_in || sample_count == N-1) begin
                    done_r <= 1'b1;
                    sample_count <= 0;
                end else begin
                    sample_count <= sample_count + 1'b1;
                end
            end else begin
                voxel_out_r <= {OUT_W{1'b0}};
                valid_out_r <= 1'b0;
            end
        end
    end

endmodule