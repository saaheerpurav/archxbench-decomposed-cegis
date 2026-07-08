`timescale 1ns/1ps

module newton_root_verify_fixed #(
    parameter WIDTH = 16,
    parameter EXT_WIDTH = 64
)(
    input signed [EXT_WIDTH-1:0] poly,
    input signed [WIDTH-1:0] tolerance,
    output valid
);

    wire signed [EXT_WIDTH-1:0] tol_ext = {{(EXT_WIDTH-WIDTH){tolerance[WIDTH-1]}}, tolerance};
    wire signed [EXT_WIDTH-1:0] abs_poly = poly[EXT_WIDTH-1] ? -poly : poly;
    wire signed [EXT_WIDTH-1:0] abs_tol = tol_ext[EXT_WIDTH-1] ? -tol_ext : tol_ext;

    assign valid = (abs_poly <= abs_tol);

endmodule