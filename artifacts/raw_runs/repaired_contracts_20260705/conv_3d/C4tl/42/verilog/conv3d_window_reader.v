`timescale 1ns/1ps

module conv3d_window_reader #(
    parameter K1 = 3,
    parameter K2 = 3,
    parameter K3 = 3,
    parameter D = 8,
    parameter H = 64,
    parameter W = 64,
    parameter DATA_W = 8
) (
    input [D*H*W*DATA_W-1:0] volume_flat,
    input [clog2(D*H*W+1)-1:0] current_idx,
    input [DATA_W-1:0] current_voxel,
    input [clog2(W)-1:0] x_pos,
    input [clog2(H)-1:0] y_pos,
    input [clog2(D)-1:0] z_pos,
    output reg [K1*K2*K3*DATA_W-1:0] window_flat
);

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

    integer dz, dy, dx;
    integer src_z, src_y, src_x;
    integer src_idx;
    integer win_idx;

    always @* begin
        window_flat = {K1*K2*K3*DATA_W{1'b0}};

        for (dz = 0; dz < K1; dz = dz + 1) begin
            for (dy = 0; dy < K2; dy = dy + 1) begin
                for (dx = 0; dx < K3; dx = dx + 1) begin
                    src_z = z_pos - (K1 - 1) + dz;
                    src_y = y_pos - (K2 - 1) + dy;
                    src_x = x_pos - (K3 - 1) + dx;
                    src_idx = (src_z * H * W) + (src_y * W) + src_x;
                    win_idx = ((dz * K2 * K3) + (dy * K3) + dx) * DATA_W;

                    if (src_z >= 0 && src_z < D &&
                        src_y >= 0 && src_y < H &&
                        src_x >= 0 && src_x < W) begin
                        if (src_idx == current_idx)
                            window_flat[win_idx +: DATA_W] = current_voxel;
                        else
                            window_flat[win_idx +: DATA_W] = volume_flat[src_idx*DATA_W +: DATA_W];
                    end
                end
            end
        end
    end

endmodule