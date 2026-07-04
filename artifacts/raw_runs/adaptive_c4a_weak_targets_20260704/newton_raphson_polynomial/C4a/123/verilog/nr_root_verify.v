`timescale 1ns/1ps

module nr_root_verify #(
    parameter WIDTH = 16,
    parameter EXT = WIDTH * 4
)(
    input  signed [EXT-1:0]   poly_value,
    input  signed [WIDTH-1:0] tolerance,
    output                    valid
);

    wire signed [EXT-1:0] tol_ext;
    wire signed [EXT-1:0] abs_poly;

    assign tol_ext  = {{(EXT-WIDTH){tolerance[WIDTH-1]}}, tolerance};
    assign abs_poly = poly_value[EXT-1] ? -poly_value : poly_value;

    assign valid = (tolerance >= 0) && (abs_poly >= 0) && (abs_poly <= tol_ext);

endmodule