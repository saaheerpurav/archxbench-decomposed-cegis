`timescale 1ns/1ps

module conv2d_out_index #(
    parameter COUT = 8,
    parameter OH = 62,
    parameter OW = 62
)(
    input  [31:0] flat_index,
    output reg [31:0] out_ch,
    output reg [31:0] out_row,
    output reg [31:0] out_col
);

    localparam integer SPATIAL_SIZE = OH * OW;

    reg [31:0] spatial_index;

    always @* begin
        spatial_index = flat_index % SPATIAL_SIZE;
        out_ch        = flat_index / SPATIAL_SIZE;
        out_row       = spatial_index / OW;
        out_col       = spatial_index % OW;
    end

endmodule