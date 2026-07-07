`timescale 1ns/1ps

module nr_root_verify #(
    parameter WIDTH = 16,
    parameter FRAC = 8,
    parameter signed [WIDTH-1:0] TOLERANCE = 8
)(
    input signed [(4*WIDTH)-1:0] poly,
    output valid
);

    localparam EXT = 4 * WIDTH;

    wire signed [EXT:0] poly_ext;
    wire signed [EXT:0] tol_ext;

    wire [EXT:0] abs_poly;
    wire [EXT:0] abs_tolerance;

    assign poly_ext = {poly[EXT-1], poly};
    assign tol_ext  = {{(EXT + 1 - WIDTH){TOLERANCE[WIDTH-1]}}, TOLERANCE};

    assign abs_poly      = poly_ext[EXT] ? -poly_ext : poly_ext;
    assign abs_tolerance = tol_ext[EXT]  ? -tol_ext  : tol_ext;

    assign valid = (abs_poly <= abs_tolerance);

endmodule