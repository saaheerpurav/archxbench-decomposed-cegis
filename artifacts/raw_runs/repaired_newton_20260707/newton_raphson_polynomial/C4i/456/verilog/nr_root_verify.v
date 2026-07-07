`timescale 1ns/1ps

module nr_root_verify #(
    parameter WIDTH = 16,
    parameter FRAC = 8,
    parameter signed [WIDTH-1:0] TOLERANCE = 8
)(
    input signed [WIDTH-1:0] poly_value,
    output valid
);

    wire signed [WIDTH:0] poly_ext;
    wire [WIDTH:0] abs_poly;
    wire signed [WIDTH:0] tolerance_ext;

    assign poly_ext = {poly_value[WIDTH-1], poly_value};
    assign abs_poly = poly_ext[WIDTH] ? -poly_ext : poly_ext;
    assign tolerance_ext = {TOLERANCE[WIDTH-1], TOLERANCE};

    assign valid = (tolerance_ext >= 0) && (abs_poly <= tolerance_ext[WIDTH:0]);

endmodule