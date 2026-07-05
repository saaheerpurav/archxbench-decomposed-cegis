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
    localparam COUNT_W = 32;

    reg [DATA_W-1:0] volume_mem [0:N-1];
    reg [COUNT_W-1:0] in_count;

    wire [COUNT_W-1:0] z_pos;
    wire [COUNT_W-1:0] y_pos;
    wire [COUNT_W-1:0] x_pos;
    wire window_valid;
    wire [KW*DATA_W-1:0] window_flat;
    wire [OUT_W-1:0] mac_sum;

    reg [OUT_W-1:0] voxel_out_r;
    reg valid_out_r;
    reg done_r;

    assign voxel_out = voxel_out_r;
    assign valid_out = valid_out_r;
    assign done = done_r;

    conv3d_coord_decode #(
        .H(H),
        .W(W)
    ) u_coord_decode (
        .linear_idx(in_count),
        .z_pos(z_pos),
        .y_pos(y_pos),
        .x_pos(x_pos)
    );

    conv3d_window_valid #(
        .K1(K1),
        .K2(K2),
        .K3(K3)
    ) u_window_valid (
        .z_pos(z_pos),
        .y_pos(y_pos),
        .x_pos(x_pos),
        .valid(window_valid)
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
    ) u_window_extract (
        .volume_mem_flat_dummy(1'b0),
        .current_idx(in_count),
        .current_voxel(voxel_in),
        .z_pos(z_pos),
        .y_pos(y_pos),
        .x_pos(x_pos),
        .mem0(volume_mem[((z_pos-(K1-1)+0)*H*W)+((y_pos-(K2-1)+0)*W)+(x_pos-(K3-1)+0)]),
        .mem1(volume_mem[((z_pos-(K1-1)+0)*H*W)+((y_pos-(K2-1)+0)*W)+(x_pos-(K3-1)+1)]),
        .mem2(volume_mem[((z_pos-(K1-1)+0)*H*W)+((y_pos-(K2-1)+0)*W)+(x_pos-(K3-1)+2)]),
        .mem3(volume_mem[((z_pos-(K1-1)+0)*H*W)+((y_pos-(K2-1)+1)*W)+(x_pos-(K3-1)+0)]),
        .mem4(volume_mem[((z_pos-(K1-1)+0)*H*W)+((y_pos-(K2-1)+1)*W)+(x_pos-(K3-1)+1)]),
        .mem5(volume_mem[((z_pos-(K1-1)+0)*H*W)+((y_pos-(K2-1)+1)*W)+(x_pos-(K3-1)+2)]),
        .mem6(volume_mem[((z_pos-(K1-1)+0)*H*W)+((y_pos-(K2-1)+2)*W)+(x_pos-(K3-1)+0)]),
        .mem7(volume_mem[((z_pos-(K1-1)+0)*H*W)+((y_pos-(K2-1)+2)*W)+(x_pos-(K3-1)+1)]),
        .mem8(volume_mem[((z_pos-(K1-1)+0)*H*W)+((y_pos-(K2-1)+2)*W)+(x_pos-(K3-1)+2)]),
        .mem9(volume_mem[((z_pos-(K1-1)+1)*H*W)+((y_pos-(K2-1)+0)*W)+(x_pos-(K3-1)+0)]),
        .mem10(volume_mem[((z_pos-(K1-1)+1)*H*W)+((y_pos-(K2-1)+0)*W)+(x_pos-(K3-1)+1)]),
        .mem11(volume_mem[((z_pos-(K1-1)+1)*H*W)+((y_pos-(K2-1)+0)*W)+(x_pos-(K3-1)+2)]),
        .mem12(volume_mem[((z_pos-(K1-1)+1)*H*W)+((y_pos-(K2-1)+1)*W)+(x_pos-(K3-1)+0)]),
        .mem13(volume_mem[((z_pos-(K1-1)+1)*H*W)+((y_pos-(K2-1)+1)*W)+(x_pos-(K3-1)+1)]),
        .mem14(volume_mem[((z_pos-(K1-1)+1)*H*W)+((y_pos-(K2-1)+1)*W)+(x_pos-(K3-1)+2)]),
        .mem15(volume_mem[((z_pos-(K1-1)+1)*H*W)+((y_pos-(K2-1)+2)*W)+(x_pos-(K3-1)+0)]),
        .mem16(volume_mem[((z_pos-(K1-1)+1)*H*W)+((y_pos-(K2-1)+2)*W)+(x_pos-(K3-1)+1)]),
        .mem17(volume_mem[((z_pos-(K1-1)+1)*H*W)+((y_pos-(K2-1)+2)*W)+(x_pos-(K3-1)+2)]),
        .mem18(volume_mem[((z_pos-(K1-1)+2)*H*W)+((y_pos-(K2-1)+0)*W)+(x_pos-(K3-1)+0)]),
        .mem19(volume_mem[((z_pos-(K1-1)+2)*H*W)+((y_pos-(K2-1)+0)*W)+(x_pos-(K3-1)+1)]),
        .mem20(volume_mem[((z_pos-(K1-1)+2)*H*W)+((y_pos-(K2-1)+0)*W)+(x_pos-(K3-1)+2)]),
        .mem21(volume_mem[((z_pos-(K1-1)+2)*H*W)+((y_pos-(K2-1)+1)*W)+(x_pos-(K3-1)+0)]),
        .mem22(volume_mem[((z_pos-(K1-1)+2)*H*W)+((y_pos-(K2-1)+1)*W)+(x_pos-(K3-1)+1)]),
        .mem23(volume_mem[((z_pos-(K1-1)+2)*H*W)+((y_pos-(K2-1)+1)*W)+(x_pos-(K3-1)+2)]),
        .mem24(volume_mem[((z_pos-(K1-1)+2)*H*W)+((y_pos-(K2-1)+2)*W)+(x_pos-(K3-1)+0)]),
        .mem25(volume_mem[((z_pos-(K1-1)+2)*H*W)+((y_pos-(K2-1)+2)*W)+(x_pos-(K3-1)+1)]),
        .mem26(volume_mem[((z_pos-(K1-1)+2)*H*W)+((y_pos-(K2-1)+2)*W)+(x_pos-(K3-1)+2)]),
        .window_flat(window_flat)
    );

    conv3d_mac #(
        .K1(K1),
        .K2(K2),
        .K3(K3),
        .DATA_W(DATA_W),
        .LOG_KW(LOG_KW)
    ) u_mac (
        .window_flat(window_flat),
        .kernel(kernel),
        .sum(mac_sum)
    );

    always @(posedge clk) begin
        if (rst) begin
            in_count <= 0;
            voxel_out_r <= 0;
            valid_out_r <= 0;
            done_r <= 0;
        end else begin
            valid_out_r <= 0;
            done_r <= 0;

            if (valid_in) begin
                volume_mem[in_count] <= voxel_in;
                voxel_out_r <= mac_sum;
                valid_out_r <= window_valid;
                done_r <= last_in;

                if (last_in)
                    in_count <= 0;
                else
                    in_count <= in_count + 1;
            end
        end
    end

endmodule