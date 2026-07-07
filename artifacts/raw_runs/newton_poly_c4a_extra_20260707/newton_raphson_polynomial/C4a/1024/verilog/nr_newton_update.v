`timescale 1ns/1ps

module nr_newton_update #(
    parameter WIDTH = 16
)(
    input  signed [WIDTH-1:0] x_current,
    input  signed [WIDTH-1:0] delta,
    input                     hold,
    output signed [WIDTH-1:0] x_next
);

    localparam EXT = 2 * WIDTH;

    wire signed [EXT-1:0] x_ext;
    wire signed [EXT-1:0] delta_ext;
    wire signed [EXT-1:0] raw_next;
    wire signed [EXT-1:0] max_value;
    wire signed [EXT-1:0] min_value;
    wire signed [WIDTH-1:0] clipped_next;

    assign x_ext     = {{WIDTH{x_current[WIDTH-1]}}, x_current};
    assign delta_ext = {{WIDTH{delta[WIDTH-1]}}, delta};
    assign raw_next  = x_ext - delta_ext;

    assign max_value = {{WIDTH{1'b0}}, 1'b0, {(WIDTH-1){1'b1}}};
    assign min_value = {{WIDTH{1'b1}}, 1'b1, {(WIDTH-1){1'b0}}};

    assign clipped_next = (raw_next > max_value) ? {1'b0, {(WIDTH-1){1'b1}}} :
                          (raw_next < min_value) ? {1'b1, {(WIDTH-1){1'b0}}} :
                                                    raw_next[WIDTH-1:0];

    assign x_next = hold ? x_current : clipped_next;

endmodule