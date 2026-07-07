`timescale 1ns/1ps

module nr_poly_eval_fixed #(
    parameter WIDTH = 16,
    parameter FRAC = 8,
    parameter WIDE = WIDTH * 4
)(
    input signed [WIDE-1:0] x,
    input signed [WIDE-1:0] coeff0,
    input signed [WIDE-1:0] coeff1,
    input signed [WIDE-1:0] coeff2,
    input signed [WIDE-1:0] coeff3,
    output signed [WIDE-1:0] poly
);

    function signed [WIDE-1:0] fixed_mul;
        input signed [WIDE-1:0] a;
        input signed [WIDE-1:0] b;
        reg signed [(2*WIDE)-1:0] product;
        begin
            product = a * b;
            fixed_mul = product >>> FRAC;
        end
    endfunction

    wire signed [WIDE-1:0] h2;
    wire signed [WIDE-1:0] h1;
    wire signed [WIDE-1:0] h0;

    assign h2 = fixed_mul(coeff3, x) + coeff2;
    assign h1 = fixed_mul(h2, x) + coeff1;
    assign h0 = fixed_mul(h1, x) + coeff0;
    assign poly = h0;

endmodule