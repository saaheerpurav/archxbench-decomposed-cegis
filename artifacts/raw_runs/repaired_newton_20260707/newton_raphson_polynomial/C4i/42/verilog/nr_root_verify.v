`timescale 1ns/1ps

module nr_root_verify #(
    parameter WIDTH = 16
)(
    input signed [WIDTH-1:0] poly_value,
    input signed [WIDTH-1:0] epsilon,
    output valid_root
);

    wire [WIDTH:0] poly_mag;
    wire [WIDTH:0] eps_mag;

    assign poly_mag = poly_value[WIDTH-1]
                    ? ({1'b0, ~poly_value} + {{WIDTH{1'b0}}, 1'b1})
                    : {1'b0, poly_value};

    assign eps_mag = epsilon[WIDTH-1]
                   ? ({1'b0, ~epsilon} + {{WIDTH{1'b0}}, 1'b1})
                   : {1'b0, epsilon};

    assign valid_root = (poly_mag <= eps_mag);

endmodule