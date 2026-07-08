`timescale 1ns/1ps

module sqrt_nr_fixed_sqrt #(
    parameter N = 16,
    parameter M = 8
)(
    input  [N-1:0] X,
    output reg [N-1:0] sqrt_value
);

    function [N-1:0] isqrt;
        input [(2*N)+M-1:0] value;
        integer bit_idx;
        reg [(2*N)+M-1:0] root;
        reg [(2*N)+M-1:0] trial;
        begin
            root = {((2*N)+M){1'b0}};

            for (bit_idx = N - 1; bit_idx >= 0; bit_idx = bit_idx - 1) begin
                trial = root | ({{((2*N)+M-1){1'b0}}, 1'b1} << bit_idx);

                if ((trial * trial) <= value)
                    root = trial;
            end

            isqrt = root[N-1:0];
        end
    endfunction

    reg [(2*N)+M-1:0] scaled_x;

    always @* begin
        scaled_x = {{N{1'b0}}, X, {M{1'b0}}};
        sqrt_value = isqrt(scaled_x);
    end

endmodule