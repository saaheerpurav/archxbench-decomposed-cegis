`timescale 1ns/1ps

module conv3d_window_shift #(
    parameter K1 = 3,
    parameter K2 = 3,
    parameter K3 = 3,
    parameter DATA_W = 8
) (
    input  [K1*K2*K3*DATA_W-1:0] window_in,
    input  [DATA_W-1:0] voxel_in,
    output [K1*K2*K3*DATA_W-1:0] window_out
);

    localparam KW = K1 * K2 * K3;

    generate
        if (KW == 1) begin : gen_single_voxel_window
            assign window_out = voxel_in;
        end else begin : gen_shift_window
            assign window_out = {
                window_in[(KW-1)*DATA_W-1:0],
                voxel_in
            };
        end
    endgenerate

endmodule