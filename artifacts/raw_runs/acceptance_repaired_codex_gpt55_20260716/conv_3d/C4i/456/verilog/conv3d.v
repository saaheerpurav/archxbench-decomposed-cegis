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
    localparam OUT_W = DATA_W + LOG_KW;
    localparam KTOT = K1 * K2 * K3;
    localparam CNT_W = clog2(N + 1);
    localparam D_W = clog2(D);
    localparam H_W = clog2(H);
    localparam X_W = clog2(W);

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
            if (clog2 < 1)
                clog2 = 1;
        end
    endfunction

    reg [N*DATA_W-1:0] volume_flat;
    reg [CNT_W-1:0] in_count;
    reg [OUT_W-1:0] voxel_out_r;
    reg valid_out_r;
    reg done_r;

    wire [D_W-1:0] cur_d;
    wire [H_W-1:0] cur_h;
    wire [X_W-1:0] cur_w;
    wire window_valid;
    wire [KTOT*DATA_W-1:0] window_flat;
    wire [OUT_W-1:0] mac_sum;

    reg [N*DATA_W-1:0] volume_next;

    conv3d_coord_decode #(
        .D(D), .H(H), .W(W)
    ) u_coord_decode (
        .index(in_count),
        .d_idx(cur_d),
        .h_idx(cur_h),
        .w_idx(cur_w)
    );

    conv3d_window_valid #(
        .K1(K1), .K2(K2), .K3(K3),
        .D(D), .H(H), .W(W)
    ) u_window_valid (
        .d_idx(cur_d),
        .h_idx(cur_h),
        .w_idx(cur_w),
        .valid(window_valid)
    );

    conv3d_window_extract #(
        .K1(K1), .K2(K2), .K3(K3),
        .D(D), .H(H), .W(W),
        .DATA_W(DATA_W)
    ) u_window_extract (
        .volume_flat(volume_next),
        .d_idx(cur_d),
        .h_idx(cur_h),
        .w_idx(cur_w),
        .window_flat(window_flat)
    );

    conv3d_mac #(
        .K1(K1), .K2(K2), .K3(K3),
        .DATA_W(DATA_W),
        .LOG_KW(LOG_KW)
    ) u_mac (
        .window_flat(window_flat),
        .kernel(kernel),
        .sum(mac_sum)
    );

    always @* begin
        volume_next = volume_flat;
        if (valid_in) begin
            volume_next[in_count*DATA_W +: DATA_W] = voxel_in;
        end
    end

    always @(posedge clk) begin
        if (rst) begin
            volume_flat <= {N*DATA_W{1'b0}};
            in_count <= {CNT_W{1'b0}};
            voxel_out_r <= {OUT_W{1'b0}};
            valid_out_r <= 1'b0;
            done_r <= 1'b0;
        end else begin
            valid_out_r <= 1'b0;
            done_r <= 1'b0;

            if (valid_in) begin
                volume_flat <= volume_next;

                if (window_valid) begin
                    voxel_out_r <= mac_sum;
                    valid_out_r <= 1'b1;
                    if (last_in)
                        done_r <= 1'b1;
                end

                if (last_in)
                    in_count <= {CNT_W{1'b0}};
                else if (in_count < N[CNT_W-1:0] - 1'b1)
                    in_count <= in_count + 1'b1;
            end
        end
    end

    assign voxel_out = voxel_out_r;
    assign valid_out = valid_out_r;
    assign done = done_r;

endmodule