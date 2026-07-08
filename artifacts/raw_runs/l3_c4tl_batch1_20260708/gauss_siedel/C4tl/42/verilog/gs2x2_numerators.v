`timescale 1ns/1ps

module gs2x2_numerators #(
    parameter DATA_WIDTH = 32
)(
    input signed [DATA_WIDTH-1:0] a11,
    input signed [DATA_WIDTH-1:0] a12,
    input signed [DATA_WIDTH-1:0] a21,
    input signed [DATA_WIDTH-1:0] a22,
    input signed [DATA_WIDTH-1:0] b1,
    input signed [DATA_WIDTH-1:0] b2,
    output signed [(2*DATA_WIDTH)-1:0] num_x1,
    output signed [(2*DATA_WIDTH)-1:0] num_x2
);

    wire signed [(2*DATA_WIDTH)-1:0] b1_a22;
    wire signed [(2*DATA_WIDTH)-1:0] b2_a12;
    wire signed [(2*DATA_WIDTH)-1:0] a11_b2;
    wire signed [(2*DATA_WIDTH)-1:0] a21_b1;

    assign b1_a22 = b1 * a22;
    assign b2_a12 = b2 * a12;
    assign a11_b2 = a11 * b2;
    assign a21_b1 = a21 * b1;

    assign num_x1 = b1_a22 - b2_a12;
    assign num_x2 = a11_b2 - a21_b1;

endmodule