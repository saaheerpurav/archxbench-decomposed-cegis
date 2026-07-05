`timescale 1ns/1ps

module conv3d_window_sum #(
    parameter K1 = 3,
    parameter K2 = 3,
    parameter K3 = 3,
    parameter D = 8,
    parameter H = 64,
    parameter W = 64,
    parameter DATA_W = 8,
    parameter SUM_W = 13,
    parameter ADDR_W = 16
) (
    input volume_mem_flat,
    input [DATA_W-1:0] cur_voxel,
    input [ADDR_W-1:0] cur_index,
    input [ADDR_W-1:0] depth_idx,
    input [ADDR_W-1:0] row_idx,
    input [ADDR_W-1:0] col_idx,
    input [K1*K2*K3*DATA_W-1:0] kernel,
    output reg [SUM_W-1:0] sum_out
);

    integer kd, kh, kw;
    integer base_d, base_h, base_w;
    integer mem_idx;
    integer k_idx;
    reg [DATA_W-1:0] sample;
    reg [DATA_W-1:0] coeff;

    reg [DATA_W-1:0] volume_mem [0:D*H*W-1];

    always @(*) begin
        sum_out = {SUM_W{1'b0}};
        base_d = depth_idx - (K1 - 1);
        base_h = row_idx - (K2 - 1);
        base_w = col_idx - (K3 - 1);

        for (kd = 0; kd < K1; kd = kd + 1) begin
            for (kh = 0; kh < K2; kh = kh + 1) begin
                for (kw = 0; kw < K3; kw = kw + 1) begin
                    mem_idx = (base_d + kd) * H * W + (base_h + kh) * W + (base_w + kw);
                    k_idx = (kd * K2 * K3 + kh * K3 + kw) * DATA_W;
                    coeff = kernel[k_idx +: DATA_W];

                    if (mem_idx == cur_index) begin
                        sample = cur_voxel;
                    end else begin
                        sample = conv3d_volume_read(mem_idx);
                    end

                    sum_out = sum_out + (sample * coeff);
                end
            end
        end
    end

    function [DATA_W-1:0] conv3d_volume_read;
        input integer idx;
        begin
            conv3d_volume_read = conv3d_window_sum.volume_mem[idx];
        end
    endfunction

endmodule