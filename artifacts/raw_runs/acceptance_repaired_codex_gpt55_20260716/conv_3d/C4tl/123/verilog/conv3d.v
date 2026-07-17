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
    output reg [DATA_W+LOG_KW-1:0] voxel_out,
    output reg valid_out,
    output reg done
);

    localparam N = D * H * W;
    localparam KW = K1 * K2 * K3;
    localparam OUT_W = DATA_W + LOG_KW;
    localparam ADDR_W = 32;

    reg [DATA_W-1:0] volume_mem [0:N-1];
    reg [ADDR_W-1:0] write_ptr;

    wire [ADDR_W-1:0] cur_d;
    wire [ADDR_W-1:0] cur_h;
    wire [ADDR_W-1:0] cur_w;
    wire window_valid;
    wire done_comb;
    wire [KW*ADDR_W-1:0] window_addrs;
    wire [KW*DATA_W-1:0] window_voxels;
    wire [OUT_W-1:0] mac_sum;

    integer wi;
    integer wd;
    integer wh;
    integer ww;
    integer flat_idx;
    integer mem_addr;

    conv3d_index_decode #(
        .D(D), .H(H), .W(W)
    ) u_index_decode (
        .linear_idx(write_ptr),
        .d(cur_d),
        .h(cur_h),
        .w(cur_w)
    );

    conv3d_window_valid #(
        .K1(K1), .K2(K2), .K3(K3),
        .D(D), .H(H), .W(W)
    ) u_window_valid (
        .d(cur_d),
        .h(cur_h),
        .w(cur_w),
        .valid_in(valid_in),
        .window_valid(window_valid)
    );

    conv3d_window_addresses #(
        .K1(K1), .K2(K2), .K3(K3),
        .D(D), .H(H), .W(W),
        .ADDR_W(ADDR_W)
    ) u_window_addresses (
        .d(cur_d),
        .h(cur_h),
        .w(cur_w),
        .addrs(window_addrs)
    );

    conv3d_mac_tree #(
        .K1(K1), .K2(K2), .K3(K3),
        .DATA_W(DATA_W),
        .LOG_KW(LOG_KW)
    ) u_mac_tree (
        .window(window_voxels),
        .kernel(kernel),
        .sum(mac_sum)
    );

    conv3d_done_logic u_done_logic (
        .valid_window(window_valid),
        .last_in(last_in),
        .done_out(done_comb)
    );

    assign window_voxels = make_window_voxels(window_addrs, voxel_in, write_ptr, valid_in);

    function [KW*DATA_W-1:0] make_window_voxels;
        input [KW*ADDR_W-1:0] addrs;
        input [DATA_W-1:0] cur_voxel;
        input [ADDR_W-1:0] cur_write_ptr;
        input cur_valid;
        integer i;
        integer a;
        reg [DATA_W-1:0] v;
        begin
            make_window_voxels = {KW*DATA_W{1'b0}};
            for (i = 0; i < KW; i = i + 1) begin
                a = addrs[i*ADDR_W +: ADDR_W];
                if (cur_valid && a == cur_write_ptr)
                    v = cur_voxel;
                else if (a >= 0 && a < N)
                    v = volume_mem[a];
                else
                    v = {DATA_W{1'b0}};
                make_window_voxels[i*DATA_W +: DATA_W] = v;
            end
        end
    endfunction

    always @(posedge clk) begin
        if (rst) begin
            write_ptr <= 0;
            voxel_out <= {OUT_W{1'b0}};
            valid_out <= 1'b0;
            done <= 1'b0;
        end else begin
            valid_out <= 1'b0;
            done <= 1'b0;

            if (valid_in) begin
                volume_mem[write_ptr] <= voxel_in;
                voxel_out <= mac_sum;
                valid_out <= window_valid;
                done <= done_comb;

                if (last_in)
                    write_ptr <= 0;
                else if (write_ptr == N-1)
                    write_ptr <= 0;
                else
                    write_ptr <= write_ptr + 1;
            end
        end
    end

endmodule