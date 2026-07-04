`timescale 1ns/1ps

module nr_convergence_check #(
    parameter WIDTH = 16,
    parameter EXT = WIDTH * 4
)(
    input  signed [EXT-1:0]   value,
    input  signed [WIDTH-1:0] tolerance,
    output                    within_tolerance
);

    wire [EXT-1:0] value_mag;
    wire [WIDTH-1:0] tolerance_mag;
    wire [EXT-1:0] tolerance_ext;

    assign value_mag = value[EXT-1] ? (~value + {{(EXT-1){1'b0}}, 1'b1}) : value;

    assign tolerance_mag = tolerance[WIDTH-1]
                          ? (~tolerance + {{(WIDTH-1){1'b0}}, 1'b1})
                          : tolerance;

    assign tolerance_ext = {{(EXT-WIDTH){1'b0}}, tolerance_mag};

    assign within_tolerance = (value_mag <= tolerance_ext);

endmodule