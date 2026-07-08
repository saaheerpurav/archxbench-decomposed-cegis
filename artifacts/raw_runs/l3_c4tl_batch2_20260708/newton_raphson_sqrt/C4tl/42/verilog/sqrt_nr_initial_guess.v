`timescale 1ns/1ps

module sqrt_nr_initial_guess #(
    parameter N = 16,
    parameter M = 8
)(
    input  [N-1:0] x,
    output reg [N-1:0] initial_guess
);

    integer i;
    integer msb_index;
    integer sqrt_bit_index;

    always @(*) begin
        msb_index = -1;

        for (i = 0; i < N; i = i + 1) begin
            if (x[i])
                msb_index = i;
        end

        if (msb_index < 0) begin
            initial_guess = {N{1'b0}};
        end else begin
            sqrt_bit_index = M + ((msb_index - M + 1) / 2);

            if (sqrt_bit_index < 0)
                sqrt_bit_index = 0;
            else if (sqrt_bit_index >= N)
                sqrt_bit_index = N - 1;

            initial_guess = ({N{1'b0}} | ({{(N-1){1'b0}}, 1'b1} << sqrt_bit_index));
        end
    end

endmodule