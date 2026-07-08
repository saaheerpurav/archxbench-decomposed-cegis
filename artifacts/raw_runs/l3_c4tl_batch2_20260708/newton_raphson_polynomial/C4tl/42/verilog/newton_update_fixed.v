`timescale 1ns/1ps

module newton_update_fixed #(
    parameter FRAC = 8,
    parameter EXT_WIDTH = 64
)(
    input signed [EXT_WIDTH-1:0] x,
    input signed [EXT_WIDTH-1:0] poly,
    input signed [EXT_WIDTH-1:0] deriv,
    output signed [EXT_WIDTH-1:0] x_next
);

    wire signed [(2*EXT_WIDTH)-1:0] numerator;
    wire signed [EXT_WIDTH-1:0] delta;

    assign numerator = {{EXT_WIDTH{poly[EXT_WIDTH-1]}}, poly} <<< FRAC;
    assign delta = (deriv == {EXT_WIDTH{1'b0}}) ? {EXT_WIDTH{1'b0}} : (numerator / deriv);
    assign x_next = (deriv == {EXT_WIDTH{1'b0}}) ? x : (x - delta);

endmodule