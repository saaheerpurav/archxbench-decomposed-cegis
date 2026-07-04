`timescale 1ns/1ps

module fp_mult_normalize (
    input [47:0] product,
    input signed [10:0] exp_in,
    output reg [23:0] mantissa,
    output reg signed [10:0] exp_out,
    output reg guard_bit,
    output reg round_bit,
    output reg sticky_bit
);

always @* begin
    if (product[47]) begin
        mantissa = product[47:24];
        exp_out = exp_in + 11'sd1;
        guard_bit = product[23];
        round_bit = product[22];
        sticky_bit = |product[21:0];
    end else begin
        mantissa = product[46:23];
        exp_out = exp_in;
        guard_bit = product[22];
        round_bit = product[21];
        sticky_bit = |product[20:0];
    end
end

endmodule