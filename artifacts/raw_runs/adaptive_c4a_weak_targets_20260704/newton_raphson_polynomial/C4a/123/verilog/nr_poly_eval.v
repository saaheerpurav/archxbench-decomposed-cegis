`timescale 1ns/1ps

module nr_poly_eval #(
    parameter WIDTH = 16,
    parameter FRAC  = 8,
    parameter EXT   = WIDTH * 4
)(
    input  signed [EXT-1:0]   x,
    input  signed [WIDTH-1:0] coeff0,
    input  signed [WIDTH-1:0] coeff1,
    input  signed [WIDTH-1:0] coeff2,
    input  signed [WIDTH-1:0] coeff3,
    output signed [EXT-1:0]   poly
);

    wire signed [EXT-1:0] c0;
    wire signed [EXT-1:0] c1;
    wire signed [EXT-1:0] c2;
    wire signed [EXT-1:0] c3;

    assign c0 = {{(EXT-WIDTH){coeff0[WIDTH-1]}}, coeff0};
    assign c1 = {{(EXT-WIDTH){coeff1[WIDTH-1]}}, coeff1};
    assign c2 = {{(EXT-WIDTH){coeff2[WIDTH-1]}}, coeff2};
    assign c3 = {{(EXT-WIDTH){coeff3[WIDTH-1]}}, coeff3};

    function signed [EXT-1:0] fixed_mul;
        input signed [EXT-1:0] a;
        input signed [EXT-1:0] b;
        reg   signed [(2*EXT)-1:0] product;
        begin
            product   = a * b;
            fixed_mul = product >>> FRAC;
        end
    endfunction

    wire signed [EXT-1:0] h2;
    wire signed [EXT-1:0] h1;

    assign h2   = fixed_mul(c3, x) + c2;
    assign h1   = fixed_mul(h2, x) + c1;
    assign poly = fixed_mul(h1, x) + c0;

endmodule