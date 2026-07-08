`timescale 1ns/1ps

module sqrt_nr_iteration #(
    parameter N = 16,
    parameter M = 8
)(
    input  [N-1:0] X,
    input  [N-1:0] y_current,
    output reg [N-1:0] y_next
);

    localparam W = (2 * N) + M;

    reg [W-1:0] scaled_x;
    reg [W-1:0] quotient;
    reg [W-1:0] sum;
    reg [W-1:0] half_sum;

    always @* begin
        scaled_x = {W{1'b0}};
        quotient = {W{1'b0}};
        sum      = {W{1'b0}};
        half_sum = {W{1'b0}};
        y_next   = {N{1'b0}};

        if (X == {N{1'b0}}) begin
            y_next = {N{1'b0}};
        end else if (y_current == {N{1'b0}}) begin
            y_next = {{(N-1){1'b0}}, 1'b1};
        end else begin
            scaled_x = {{(W-N){1'b0}}, X} << M;
            quotient = scaled_x / {{(W-N){1'b0}}, y_current};
            sum      = quotient + {{(W-N){1'b0}}, y_current};
            half_sum = sum >> 1;

            if (half_sum > {{(W-N){1'b0}}, {N{1'b1}}})
                y_next = {N{1'b1}};
            else
                y_next = half_sum[N-1:0];
        end
    end

endmodule