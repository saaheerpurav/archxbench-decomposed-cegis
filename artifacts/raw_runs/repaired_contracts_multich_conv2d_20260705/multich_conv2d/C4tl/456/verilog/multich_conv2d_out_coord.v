`timescale 1ns/1ps

module multich_conv2d_out_coord #(
    parameter COUT = 8,
    parameter OUT_H = 62,
    parameter OUT_WID = 62
)(
    input  [31:0] flat_index,
    output reg [31:0] out_ch,
    output reg [31:0] out_row,
    output reg [31:0] out_col,
    output reg valid
);

    localparam [31:0] OUT_SPATIAL = OUT_H * OUT_WID;
    localparam [31:0] OUT_TOTAL   = COUT * OUT_SPATIAL;

    reg [31:0] spatial_index;

    always @* begin
        valid = 1'b0;
        out_ch = 32'd0;
        out_row = 32'd0;
        out_col = 32'd0;
        spatial_index = 32'd0;

        if (flat_index < OUT_TOTAL) begin
            valid = 1'b1;

            out_ch = flat_index / OUT_SPATIAL;
            spatial_index = flat_index % OUT_SPATIAL;

            out_row = spatial_index / OUT_WID;
            out_col = spatial_index % OUT_WID;
        end
    end

endmodule