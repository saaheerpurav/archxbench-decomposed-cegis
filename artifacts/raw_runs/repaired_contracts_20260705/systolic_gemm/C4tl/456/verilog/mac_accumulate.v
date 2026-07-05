module mac_accumulate(a_value, b_value, accumulator_in, accumulator_out);
    input [31:0] a_value;
    input [31:0] b_value;
    input [63:0] accumulator_in;
    output [63:0] accumulator_out;

    assign accumulator_out = accumulator_in + ($signed(a_value) * $signed(b_value));
endmodule