`timescale 1ns/1ps

module nr_root_verifier #(
    parameter WIDTH = 16,
    parameter signed [WIDTH-1:0] TOLERANCE = 8
)(
    input  signed [WIDTH-1:0] poly_value,
    output valid
);
    wire signed [WIDTH:0] poly_ext;
    wire signed [WIDTH:0] tol_ext;
    wire        [WIDTH:0] abs_poly;
    wire        [WIDTH:0] abs_tolerance;

    assign poly_ext = {poly_value[WIDTH-1], poly_value};
    assign tol_ext  = {TOLERANCE[WIDTH-1], TOLERANCE};

    assign abs_poly      = poly_ext[WIDTH] ? $unsigned(-poly_ext) : $unsigned(poly_ext);
    assign abs_tolerance = tol_ext[WIDTH]  ? $unsigned(-tol_ext)  : $unsigned(tol_ext);

    assign valid = (abs_poly <= abs_tolerance);
endmodule