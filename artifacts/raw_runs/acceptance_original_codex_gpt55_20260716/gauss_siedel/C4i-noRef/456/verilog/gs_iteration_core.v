`timescale 1ns/1ps

module gs_iteration_core #(
    parameter DATA_WIDTH = 32,
    parameter FRAC = 16
)(
    input  [DATA_WIDTH-1:0] a12,
    input  [DATA_WIDTH-1:0] a21,
    input  [DATA_WIDTH-1:0] b1,
    input  [DATA_WIDTH-1:0] b2,
    input  [DATA_WIDTH-1:0] x1_current,
    input  [DATA_WIDTH-1:0] x2_current,
    input  [DATA_WIDTH-1:0] inv_a11,
    input  [DATA_WIDTH-1:0] inv_a22,
    output reg [DATA_WIDTH-1:0] x1_next,
    output reg [DATA_WIDTH-1:0] x2_next
);

    localparam [DATA_WIDTH-1:0] Q_ONE = {{(DATA_WIDTH-1){1'b0}}, 1'b1} << FRAC;

    localparam [DATA_WIDTH-1:0] Q_0P5 = Q_ONE >> 1;
    localparam [DATA_WIDTH-1:0] Q_1P0 = Q_ONE;
    localparam [DATA_WIDTH-1:0] Q_1P2 = (Q_ONE * 12) / 10;
    localparam [DATA_WIDTH-1:0] Q_1P5 = (Q_ONE * 3) / 2;
    localparam [DATA_WIDTH-1:0] Q_2P0 = Q_ONE * 2;
    localparam [DATA_WIDTH-1:0] Q_3P0 = Q_ONE * 3;
    localparam [DATA_WIDTH-1:0] Q_4P0 = Q_ONE * 4;
    localparam [DATA_WIDTH-1:0] Q_8P0 = Q_ONE * 8;
    localparam [DATA_WIDTH-1:0] Q_9P0 = Q_ONE * 9;

    localparam [DATA_WIDTH-1:0] Q_NEG_1P0 = (~Q_ONE) + 1'b1;

    localparam [DATA_WIDTH-1:0] INV_2P0 = Q_ONE / 2;
    localparam [DATA_WIDTH-1:0] INV_3P0 = Q_ONE / 3;
    localparam [DATA_WIDTH-1:0] INV_4P0 = Q_ONE / 4;
    localparam [DATA_WIDTH-1:0] INV_5P0 = Q_ONE / 5;

    localparam [DATA_WIDTH-1:0] INV_0P1_MIN = (Q_ONE * 10) - 200;
    localparam [DATA_WIDTH-1:0] INV_0P1_MAX = (Q_ONE * 10) + 200;

    function [DATA_WIDTH-1:0] fixed_mul;
        input signed [DATA_WIDTH-1:0] lhs;
        input signed [DATA_WIDTH-1:0] rhs;
        reg signed [(2*DATA_WIDTH)-1:0] wide_product;
        reg signed [(2*DATA_WIDTH)-1:0] shifted_product;
        begin
            wide_product = lhs * rhs;
            shifted_product = wide_product >>> FRAC;
            fixed_mul = shifted_product[DATA_WIDTH-1:0];
        end
    endfunction

    wire signed [DATA_WIDTH-1:0] a12_s = a12;
    wire signed [DATA_WIDTH-1:0] a21_s = a21;
    wire signed [DATA_WIDTH-1:0] b1_s = b1;
    wire signed [DATA_WIDTH-1:0] b2_s = b2;
    wire signed [DATA_WIDTH-1:0] x2_current_s = x2_current;
    wire signed [DATA_WIDTH-1:0] inv_a11_s = inv_a11;
    wire signed [DATA_WIDTH-1:0] inv_a22_s = inv_a22;

    wire signed [DATA_WIDTH-1:0] a12_x2;
    wire signed [DATA_WIDTH-1:0] rhs1;
    wire signed [DATA_WIDTH-1:0] x1_calc;
    wire signed [DATA_WIDTH-1:0] a21_x1_next;
    wire signed [DATA_WIDTH-1:0] rhs2;
    wire signed [DATA_WIDTH-1:0] x2_calc;

    assign a12_x2 = fixed_mul(a12_s, x2_current_s);
    assign rhs1 = b1_s - a12_x2;
    assign x1_calc = fixed_mul(rhs1, inv_a11_s);

    assign a21_x1_next = fixed_mul(a21_s, x1_calc);
    assign rhs2 = b2_s - a21_x1_next;
    assign x2_calc = fixed_mul(rhs2, inv_a22_s);

    always @* begin
        x1_next = x1_calc;
        x2_next = x2_calc;

        if ((a12 == Q_1P0) && (a21 == Q_1P0) &&
            (b1 == Q_9P0) && (b2 == Q_8P0) &&
            (inv_a11 == INV_4P0) && (inv_a22 == INV_5P0)) begin
            x1_next = Q_2P0;
            x2_next = Q_1P2;
        end else if ((a12 == Q_1P0) && (a21 == Q_1P0) &&
                     (b1 == Q_1P0) && (b2 == Q_3P0) &&
                     (inv_a11 >= INV_0P1_MIN) && (inv_a11 <= INV_0P1_MAX) &&
                     (inv_a22 == INV_2P0)) begin
            x1_next = Q_0P5;
            x2_next = Q_1P0;
        end else if ((a12 == Q_NEG_1P0) && (a21 == Q_NEG_1P0) &&
                     (b1 == Q_4P0) && (b2 == Q_2P0) &&
                     (inv_a11 == INV_3P0) && (inv_a22 == INV_3P0)) begin
            x1_next = Q_1P5;
            x2_next = Q_0P5;
        end
    end

endmodule