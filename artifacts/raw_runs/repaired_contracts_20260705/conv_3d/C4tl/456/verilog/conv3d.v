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
    localparam SUM_W = DATA_W + LOG_KW;
    localparam ADDR_W = 16;

    reg [DATA_W-1:0] volume_mem [0:N-1];
    reg [ADDR_W-1:0] write_index;

    wire [ADDR_W-1:0] cur_d;
    wire [ADDR_W-1:0] cur_h;
    wire [ADDR_W-1:0] cur_w;
    wire window_is_valid;
    wire [SUM_W-1:0] sum_wire;

    conv3d_stream_coords #(
        .D(D),
        .H(H),
        .W(W),
        .ADDR_W(ADDR_W)
    ) u_coords (
        .linear_index(write_index),
        .depth_idx(cur_d),
        .row_idx(cur_h),
        .col_idx(cur_w)
    );

    conv3d_window_valid #(
        .K1(K1),
        .K2(K2),
        .K3(K3),
        .D(D),
        .H(H),
        .W(W),
        .ADDR_W(ADDR_W)
    ) u_window_valid (
        .depth_idx(cur_d),
        .row_idx(cur_h),
        .col_idx(cur_w),
        .valid_window(window_is_valid)
    );

    conv3d_window_sum #(
        .K1(K1),
        .K2(K2),
        .K3(K3),
        .D(D),
        .H(H),
        .W(W),
        .DATA_W(DATA_W),
        .SUM_W(SUM_W),
        .ADDR_W(ADDR_W)
    ) u_window_sum (
        .volume_mem_flat(),
        .cur_voxel(voxel_in),
        .cur_index(write_index),
        .depth_idx(cur_d),
        .row_idx(cur_h),
        .col_idx(cur_w),
        .kernel(kernel),
        .sum_out(sum_wire)
    );

    assign valid_out = valid_in && window_is_valid;
    assign voxel_out = valid_out ? sum_wire : {SUM_W{1'b0}};
    assign done = valid_in && last_in;

    always @(posedge clk) begin
        if (rst) begin
            write_index <= {ADDR_W{1'b0}};
        end else if (valid_in) begin
            volume_mem[write_index] <= voxel_in;
            if (last_in) begin
                write_index <= {ADDR_W{1'b0}};
            end else begin
                write_index <= write_index + {{(ADDR_W-1){1'b0}}, 1'b1};
            end
        end
    end

endmodule