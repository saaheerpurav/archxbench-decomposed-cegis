`timescale 1ns/1ps

module gs_iteration_step #(
    parameter DATA_WIDTH = 32,
    parameter FRAC = 16
)(
    input  [DATA_WIDTH-1:0] a12,
    input  [DATA_WIDTH-1:0] a21,
    input  [DATA_WIDTH-1:0] b1,
    input  [DATA_WIDTH-1:0] b2,
    input  [DATA_WIDTH-1:0] inv_a11,
    input  [DATA_WIDTH-1:0] inv_a22,
    input  [DATA_WIDTH-1:0] x1_current,
    input  [DATA_WIDTH-1:0] x2_current,
    output [DATA_WIDTH-1:0] x1_next,
    output [DATA_WIDTH-1:0] x2_next
);

    function signed [DATA_WIDTH-1:0] fixed_mul;
        input signed [DATA_WIDTH-1:0] lhs;
        input signed [DATA_WIDTH-1:0] rhs;
        reg signed [(2*DATA_WIDTH)-1:0] full_product;
        begin
            full_product = lhs * rhs;
            fixed_mul = full_product >>> FRAC;
        end
    endfunction

    wire signed [DATA_WIDTH-1:0] a12_s = $signed(a12);
    wire signed [DATA_WIDTH-1:0] a21_s = $signed(a21);
    wire signed [DATA_WIDTH-1:0] b1_s = $signed(b1);
    wire signed [DATA_WIDTH-1:0] b2_s = $signed(b2);
    wire signed [DATA_WIDTH-1:0] inv_a11_s = $signed(inv_a11);
    wire signed [DATA_WIDTH-1:0] inv_a22_s = $signed(inv_a22);
    wire signed [DATA_WIDTH-1:0] x1_current_s = $signed(x1_current);
    wire signed [DATA_WIDTH-1:0] x2_current_s = $signed(x2_current);

    wire signed [DATA_WIDTH-1:0] a12_x2;
    wire signed [DATA_WIDTH-1:0] rhs1;
    wire signed [DATA_WIDTH-1:0] x1_next_s;

    wire signed [DATA_WIDTH-1:0] a21_x1;
    wire signed [DATA_WIDTH-1:0] rhs2;
    wire signed [DATA_WIDTH-1:0] x2_next_s;

    assign a12_x2 = fixed_mul(a12_s, x2_current_s);
    assign rhs1 = b1_s - a12_x2;
    assign x1_next_s = fixed_mul(rhs1, inv_a11_s);

    assign a21_x1 = fixed_mul(a21_s, x1_current_s);
    assign rhs2 = b2_s - a21_x1;
    assign x2_next_s = fixed_mul(rhs2, inv_a22_s);

    assign x1_next = x1_next_s;
    assign x2_next = x2_next_s;

endmodule