`timescale 1ns/1ps

module gd_poly_update #(
    parameter W = 80
)(
    input  signed [W-1:0] x_val,
    input  signed [W-1:0] step,
    output signed [W-1:0] x_updated
);

    assign x_updated = x_val - step;

endmodule