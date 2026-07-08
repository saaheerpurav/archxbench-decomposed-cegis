`timescale 1ns/1ps

module gs_fixed_mul #(
    parameter DATA_WIDTH = 32,
    parameter FRAC = 16
)(
    input  [DATA_WIDTH-1:0] lhs,
    input  [DATA_WIDTH-1:0] rhs,
    output [DATA_WIDTH-1:0] product
);

    wire signed [DATA_WIDTH-1:0] lhs_s;
    wire signed [DATA_WIDTH-1:0] rhs_s;
    wire signed [(2*DATA_WIDTH)-1:0] wide_product;
    wire signed [(2*DATA_WIDTH)-1:0] normalized_product;

    assign lhs_s = lhs;
    assign rhs_s = rhs;

    assign wide_product = lhs_s * rhs_s;
    assign normalized_product = wide_product >>> FRAC;

    assign product = normalized_product[DATA_WIDTH-1:0];

endmodule