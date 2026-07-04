`timescale 1ns/1ps

module fp_mult_round (
    input  [23:0] mantissa,
    input  signed [10:0] exp_in,
    input  guard_bit,
    input  round_bit,
    input  sticky_bit,
    output reg [22:0] frac,
    output reg signed [10:0] exp_out
);

reg increment;
reg [24:0] rounded;

always @* begin
    increment = guard_bit && (round_bit || sticky_bit || mantissa[0]);

    rounded = {1'b0, mantissa} + {24'b0, increment};

    if (rounded[24]) begin
        frac = rounded[23:1];
        exp_out = exp_in + 11'sd1;
    end else begin
        frac = rounded[22:0];
        exp_out = exp_in;
    end
end

endmodule