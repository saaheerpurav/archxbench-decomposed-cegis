`timescale 1ns/1ps

module fixed_root_verifier #(
    parameter WIDTH = 16,
    parameter FRAC = 8,
    parameter signed [WIDTH-1:0] TOLERANCE = 8
)(
    input signed [WIDTH-1:0] poly_value,
    output valid
);

    wire signed [WIDTH-1:0] abs_poly;

    fixed_abs #(
        .WIDTH(WIDTH)
    ) u_abs (
        .value(poly_value),
        .abs_value(abs_poly)
    );

    assign valid = (TOLERANCE >= 0) &&
                   ($unsigned(abs_poly) <= $unsigned(TOLERANCE));

endmodule