`timescale 1ns/1ps

module sqrt_nr_result_select #(
    parameter N = 16
)(
    input  [N-1:0] X,
    input  [N-1:0] nr_value,
    input  [N-1:0] exact_value,
    output reg [N-1:0] sqrt_result
);

    always @* begin
        if (X == {N{1'b0}}) begin
            sqrt_result = {N{1'b0}};
        end else if (exact_value == {N{1'b0}}) begin
            sqrt_result = nr_value;
        end else begin
            sqrt_result = exact_value;
        end
    end

endmodule