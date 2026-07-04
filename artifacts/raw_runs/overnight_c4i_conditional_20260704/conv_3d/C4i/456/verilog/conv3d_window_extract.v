`timescale 1ns/1ps

module conv3d_window_extract #(
    parameter K1 = 3,
    parameter K2 = 3,
    parameter K3 = 3,
    parameter D = 8,
    parameter H = 64,
    parameter W = 64,
    parameter DATA_W = 8,
    parameter COUNT_W = 32
) (
    input  [D*H*W*DATA_W-1:0]       history,
    input  [COUNT_W-1:0]            linear_index,
    input  [COUNT_W-1:0]            x_pos,
    input  [COUNT_W-1:0]            y_pos,
    input  [COUNT_W-1:0]            z_pos,
    output [K1*K2*K3*DATA_W-1:0]    window_flat,
    output                          window_valid
);

    localparam N = D * H * W;
    localparam FRAME_SIZE = H * W;

    assign window_valid = (x_pos >= (K3 - 1)) &&
                          (y_pos >= (K2 - 1)) &&
                          (z_pos >= (K1 - 1));

    genvar dz;
    genvar dy;
    genvar dx;

    generate
        for (dz = 0; dz < K1; dz = dz + 1) begin : gen_d
            for (dy = 0; dy < K2; dy = dy + 1) begin : gen_h
                for (dx = 0; dx < K3; dx = dx + 1) begin : gen_w
                    assign window_flat[
                        (((dz * K2 * K3) + (dy * K3) + dx) * DATA_W) +: DATA_W
                    ] = window_valid ?
                        history[
                            ((((K1 - 1 - dz) * FRAME_SIZE) +
                              ((K2 - 1 - dy) * W) +
                              (K3 - 1 - dx)) * DATA_W) +: DATA_W
                        ] :
                        {DATA_W{1'b0}};
                end
            end
        end
    endgenerate

endmodule