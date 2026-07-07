`timescale 1ns/1ps

module nr_root_verify #(
    parameter WIDTH = 16,
    parameter FRAC = 8,
    parameter WIDE = WIDTH * 4,
    parameter signed [WIDTH-1:0] EPSILON = 8
)(
    input signed [WIDE-1:0] x,
    input signed [WIDE-1:0] coeff0,
    input signed [WIDE-1:0] coeff1,
    input signed [WIDE-1:0] coeff2,
    input signed [WIDE-1:0] coeff3,
    output valid_root
);

    wire signed [WIDE-1:0] poly_value;
    wire signed [WIDE-1:0] abs_poly;
    wire signed [WIDE-1:0] eps_ext;

    nr_poly_eval_fixed #(
        .WIDTH(WIDTH),
        .FRAC(FRAC),
        .WIDE(WIDE)
    ) verify_poly_eval (
        .x(x),
        .coeff0(coeff0),
        .coeff1(coeff1),
        .coeff2(coeff2),
        .coeff3(coeff3),
        .poly(poly_value)
    );

    assign abs_poly = poly_value[WIDE-1] ? -poly_value : poly_value;
    assign eps_ext = {{(WIDE-WIDTH){EPSILON[WIDTH-1]}}, EPSILON};
    assign valid_root = (abs_poly <= eps_ext);

endmodule