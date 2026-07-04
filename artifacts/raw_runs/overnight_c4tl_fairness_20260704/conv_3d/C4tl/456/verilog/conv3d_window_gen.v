`timescale 1ns/1ps

module conv3d_window_gen #(
    parameter K1 = 3,
    parameter K2 = 3,
    parameter K3 = 3,
    parameter D = 8,
    parameter H = 64,
    parameter W = 64,
    parameter DATA_W = 8
) (
    input [D*H*W*DATA_W-1:0] volume_flat,
    input [DATA_W-1:0] voxel_in,
    input [31:0] current_index,
    input valid_in,
    output reg [K1*K2*K3*DATA_W-1:0] window_flat
);
    integer dz;
    integer dy;
    integer dx;
    integer wz;
    integer wy;
    integer wx;
    integer src_index;
    integer out_index;
    integer cur_z;
    integer cur_y;
    integer cur_x;

    always @* begin
        window_flat = 0;
        cur_z = current_index / (H * W);
        cur_y = (current_index / W) % H;
        cur_x = current_index % W;

        for (dz = 0; dz < K1; dz = dz + 1) begin
            for (dy = 0; dy < K2; dy = dy + 1) begin
                for (dx = 0; dx < K3; dx = dx + 1) begin
                    wz = cur_z - (K1 - 1) + dz;
                    wy = cur_y - (K2 - 1) + dy;
                    wx = cur_x - (K3 - 1) + dx;
                    out_index = ((dz * K2 * K3) + (dy * K3) + dx) * DATA_W;

                    if (wz >= 0 && wz < D && wy >= 0 && wy < H && wx >= 0 && wx < W) begin
                        src_index = ((wz * H * W) + (wy * W) + wx);
                        if (valid_in && src_index == current_index) begin
                            window_flat[out_index +: DATA_W] = voxel_in;
                        end else begin
                            window_flat[out_index +: DATA_W] = volume_flat[src_index*DATA_W +: DATA_W];
                        end
                    end else begin
                        window_flat[out_index +: DATA_W] = {DATA_W{1'b0}};
                    end
                end
            end
        end
    end
endmodule