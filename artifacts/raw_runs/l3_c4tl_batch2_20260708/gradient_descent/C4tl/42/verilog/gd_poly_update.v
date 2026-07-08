`timescale 1ns/1ps

module gd_poly_update #(
    parameter N = 16
)(
    input  signed [N-1:0] x_current,
    input  signed [N-1:0] scaled_step,
    output signed [N-1:0] x_updated
);

    assign x_updated = x_current - scaled_step;

endmodule