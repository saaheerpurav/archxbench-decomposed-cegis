`timescale 1ns/1ps

module sqrt_nr_convergence #(
    parameter N = 16
)(
    input  [N-1:0] y_current,
    input  [N-1:0] y_next,
    output reg     converged
);

    reg [N-1:0] diff;

    always @* begin
        if (y_current >= y_next)
            diff = y_current - y_next;
        else
            diff = y_next - y_current;

        converged = (diff <= {{(N-1){1'b0}}, 1'b1});
    end

endmodule