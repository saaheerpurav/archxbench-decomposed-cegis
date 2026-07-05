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
    localparam KW = K1 * K2 * K3;
    localparam OUT_W = DATA_W + LOG_KW;
    localparam ACC_W = (2 * DATA_W) + LOG_KW;

    reg [DATA_W-1:0] volume_mem [0:N-1];
    reg [31:0] in_index;

    wire [31:0] cur_d;
    wire [31:0] cur_h;
    wire [31:0] cur_w;
    wire window_valid;
    wire [KW*DATA_W-1:0] window_flat;
    wire [ACC_W-1:0] mac_full;

    conv3d_stream_index #(
        .H(H),
        .W(W)
    ) u_index (
        .linear_index(in_index),
        .depth_idx(cur_d),
        .row_idx(cur_h),
        .col_idx(cur_w)
    );

    conv3d_window_valid #(
        .K1(K1),
        .K2(K2),
        .K3(K3)
    ) u_window_valid (
        .depth_idx(cur_d),
        .row_idx(cur_h),
        .col_idx(cur_w),
        .valid(window_valid)
    );

    genvar kd, kh, kw;
    generate
        for (kd = 0; kd < K1; kd = kd + 1) begin : gen_depth
            for (kh = 0; kh < K2; kh = kh + 1) begin : gen_height
                for (kw = 0; kw < K3; kw = kw + 1) begin : gen_width
                    localparam integer TAP = (kd * K2 * K3) + (kh * K3) + kw;
                    wire [31:0] rd_d = cur_d - (K1 - 1 - kd);
                    wire [31:0] rd_h = cur_h - (K2 - 1 - kh);
                    wire [31:0] rd_w = cur_w - (K3 - 1 - kw);
                    wire [31:0] rd_index = ((rd_d * H) + rd_h) * W + rd_w;

                    assign window_flat[(TAP+1)*DATA_W-1:TAP*DATA_W] =
                        (valid_in && window_valid) ?
                            ((rd_index == in_index) ? voxel_in : volume_mem[rd_index]) :
                            {DATA_W{1'b0}};
                end
            end
        end
    endgenerate

    conv3d_mac #(
        .K1(K1),
        .K2(K2),
        .K3(K3),
        .DATA_W(DATA_W),
        .LOG_KW(LOG_KW)
    ) u_mac (
        .window_flat(window_flat),
        .kernel(kernel),
        .sum(mac_full)
    );

    assign valid_out = valid_in && window_valid;
    assign voxel_out = mac_full[OUT_W-1:0];
    assign done = valid_in && last_in;

    always @(posedge clk) begin
        if (rst) begin
            in_index <= 0;
        end else if (valid_in) begin
            volume_mem[in_index] <= voxel_in;
            if (last_in) begin
                in_index <= 0;
            end else begin
                in_index <= in_index + 1;
            end
        end
    end

endmodule