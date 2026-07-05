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
    input [DATA_W*D*H*W-1:0] volume_flat,
    input [DATA_W-1:0] voxel_in,
    input [CLOG2(D*H*W)-1:0] write_index,
    input [CLOG2(W)-1:0] x_pos,
    input [CLOG2(H)-1:0] y_pos,
    input [CLOG2(D)-1:0] z_pos,
    output reg [DATA_W*K1*K2*K3-1:0] window_flat
);

    function integer CLOG2;
        input integer value;
        integer v;
        begin
            v = value - 1;
            for (CLOG2 = 0; v > 0; CLOG2 = CLOG2 + 1)
                v = v >> 1;
        end
    endfunction

    integer kz;
    integer ky;
    integer kx;
    integer out_idx;
    integer src_z;
    integer src_y;
    integer src_x;
    integer src_addr;

    always @* begin
        window_flat = {DATA_W*K1*K2*K3{1'b0}};

        for (kz = 0; kz < K1; kz = kz + 1) begin
            for (ky = 0; ky < K2; ky = ky + 1) begin
                for (kx = 0; kx < K3; kx = kx + 1) begin
                    src_z = z_pos - (K1 - 1 - kz);
                    src_y = y_pos - (K2 - 1 - ky);
                    src_x = x_pos - (K3 - 1 - kx);

                    out_idx = ((kz * K2 * K3) + (ky * K3) + kx) * DATA_W;

                    if ((src_z >= 0) && (src_z < D) &&
                        (src_y >= 0) && (src_y < H) &&
                        (src_x >= 0) && (src_x < W)) begin

                        src_addr = (src_z * H * W) + (src_y * W) + src_x;

                        if (src_addr == write_index)
                            window_flat[out_idx +: DATA_W] = voxel_in;
                        else
                            window_flat[out_idx +: DATA_W] =
                                volume_flat[src_addr*DATA_W +: DATA_W];
                    end
                end
            end
        end
    end

endmodule