`timescale 1ns/1ps

module conv1d_mac #(
    parameter DATA_W = 8
) (
    input [DATA_W-1:0] tap_0,
    input [DATA_W-1:0] tap_1,
    input [DATA_W-1:0] tap_2,
    input [DATA_W-1:0] tap_3,
    input [DATA_W-1:0] tap_4,
    input [DATA_W-1:0] tap_5,
    input [DATA_W-1:0] tap_6,
    input [4:0]        coeff_0,
    input [4:0]        coeff_1,
    input [4:0]        coeff_2,
    input [4:0]        coeff_3,
    input [4:0]        coeff_4,
    input [4:0]        coeff_5,
    input [4:0]        coeff_6,
    output [DATA_W+8:0] sum
);

    localparam SUM_W = DATA_W + 9;

    wire [SUM_W-1:0] prod_0;
    wire [SUM_W-1:0] prod_1;
    wire [SUM_W-1:0] prod_2;
    wire [SUM_W-1:0] prod_3;
    wire [SUM_W-1:0] prod_4;
    wire [SUM_W-1:0] prod_5;
    wire [SUM_W-1:0] prod_6;

    assign prod_0 = {{9{1'b0}}, tap_0} * {{(DATA_W+4){1'b0}}, coeff_0};
    assign prod_1 = {{9{1'b0}}, tap_1} * {{(DATA_W+4){1'b0}}, coeff_1};
    assign prod_2 = {{9{1'b0}}, tap_2} * {{(DATA_W+4){1'b0}}, coeff_2};
    assign prod_3 = {{9{1'b0}}, tap_3} * {{(DATA_W+4){1'b0}}, coeff_3};
    assign prod_4 = {{9{1'b0}}, tap_4} * {{(DATA_W+4){1'b0}}, coeff_4};
    assign prod_5 = {{9{1'b0}}, tap_5} * {{(DATA_W+4){1'b0}}, coeff_5};
    assign prod_6 = {{9{1'b0}}, tap_6} * {{(DATA_W+4){1'b0}}, coeff_6};

    assign sum = prod_0 + prod_1 + prod_2 + prod_3 + prod_4 + prod_5 + prod_6;

endmodule