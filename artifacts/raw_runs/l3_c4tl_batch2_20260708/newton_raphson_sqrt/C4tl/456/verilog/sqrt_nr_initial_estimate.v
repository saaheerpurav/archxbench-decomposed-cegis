`timescale 1ns/1ps

module sqrt_nr_initial_estimate #(
    parameter N = 16,
    parameter M = 8
)(
    input  [N-1:0] X,
    output reg [N-1:0] initial_y
);

    integer i;
    integer shift_amt;
    reg found;

    always @* begin
        initial_y = {N{1'b0}};
        found = 1'b0;
        shift_amt = 0;

        if (X == {N{1'b0}}) begin
            initial_y = {N{1'b0}};
        end else begin
            for (i = N - 1; i >= 0; i = i - 1) begin
                if (!found && X[i]) begin
                    shift_amt = (i + M) >> 1;

                    if (shift_amt >= N) begin
                        initial_y = {N{1'b1}};
                    end else begin
                        initial_y = ({N{1'b0}} | {{(N-1){1'b0}}, 1'b1}) << shift_amt;
                    end

                    found = 1'b1;
                end
            end
        end
    end

endmodule