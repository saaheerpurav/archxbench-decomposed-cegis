`timescale 1ns/1ps

module nr_root_verify_fixed #(
    parameter WIDTH = 16,
    parameter EXT_WIDTH = WIDTH * 4,
    parameter signed [WIDTH-1:0] TOLERANCE = 8
)(
    input signed [EXT_WIDTH-1:0] poly,
    output valid_root
);

    wire signed [EXT_WIDTH-1:0] tol_ext;
    wire signed [EXT_WIDTH-1:0] abs_poly;

    assign tol_ext = {{(EXT_WIDTH-WIDTH){TOLERANCE[WIDTH-1]}}, TOLERANCE};
    assign abs_poly = poly[EXT_WIDTH-1] ? -poly : poly;
    assign valid_root = (abs_poly <= tol_ext);

endmodule