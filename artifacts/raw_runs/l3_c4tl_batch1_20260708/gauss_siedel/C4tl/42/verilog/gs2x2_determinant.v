`timescale 1ns/1ps

module gs2x2_determinant #(
    parameter DATA_WIDTH = 32
)(
    input signed [DATA_WIDTH-1:0] a11,
    input signed [DATA_WIDTH-1:0] a12,
    input signed [DATA_WIDTH-1:0] a21,
    input signed [DATA_WIDTH-1:0] a22,
    output signed [(2*DATA_WIDTH)-1:0] det
);

    wire signed [(2*DATA_WIDTH)-1:0] prod_main;
    wire signed [(2*DATA_WIDTH)-1:0] prod_cross;

    assign prod_main  = a11 * a22;
    assign prod_cross = a12 * a21;
    assign det = prod_main - prod_cross;

endmodule