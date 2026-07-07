`timescale 1ns/1ps

module nr_update_step #(
    parameter WIDE = 64
)(
    input signed [WIDE-1:0] x,
    input signed [WIDE-1:0] delta,
    input signed [WIDE-1:0] deriv,
    output signed [WIDE-1:0] x_next
);

    assign x_next = (deriv == {WIDE{1'b0}}) ? x : (x - delta);

endmodule