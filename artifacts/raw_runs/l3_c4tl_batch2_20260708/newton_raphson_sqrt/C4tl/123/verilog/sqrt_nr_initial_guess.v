`timescale 1ns/1ps

module sqrt_nr_initial_guess #(
    parameter N = 16,
    parameter M = 8
)(
    input  [N-1:0] X,
    output reg [N-1:0] initial_guess,
    output is_zero
);

    localparam [N-1:0] ONE_FIXED = {{(N-1){1'b0}}, 1'b1} << M;

    assign is_zero = (X == {N{1'b0}});

    always @(*) begin
        if (is_zero) begin
            initial_guess = {N{1'b0}};
        end else begin
            initial_guess = ONE_FIXED;
        end
    end

endmodule