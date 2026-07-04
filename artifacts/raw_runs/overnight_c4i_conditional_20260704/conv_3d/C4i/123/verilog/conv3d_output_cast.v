`timescale 1ns/1ps

module conv3d_output_cast #(
    parameter IN_W  = 28,
    parameter OUT_W = 12
) (
    input  [IN_W-1:0]  sum_in,
    output [OUT_W-1:0] voxel_out
);

    genvar i;

    generate
        for (i = 0; i < OUT_W; i = i + 1) begin : gen_output_cast
            if (i < IN_W) begin : gen_copy_bit
                assign voxel_out[i] = sum_in[i];
            end else begin : gen_zero_extend
                assign voxel_out[i] = 1'b0;
            end
        end
    endgenerate

endmodule