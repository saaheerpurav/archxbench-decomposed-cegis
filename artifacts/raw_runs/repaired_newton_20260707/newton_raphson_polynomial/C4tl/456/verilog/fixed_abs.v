`timescale 1ns/1ps

module fixed_abs #(
    parameter WIDTH = 16
)(
    input  signed [WIDTH-1:0] value,
    output signed [WIDTH-1:0] abs_value
);

    localparam signed [WIDTH-1:0] MIN_VALUE = {1'b1, {(WIDTH-1){1'b0}}};
    localparam signed [WIDTH-1:0] MAX_VALUE = {1'b0, {(WIDTH-1){1'b1}}};

    assign abs_value = (value == MIN_VALUE) ? MAX_VALUE :
                       value[WIDTH-1]      ? -value    :
                                             value;

endmodule