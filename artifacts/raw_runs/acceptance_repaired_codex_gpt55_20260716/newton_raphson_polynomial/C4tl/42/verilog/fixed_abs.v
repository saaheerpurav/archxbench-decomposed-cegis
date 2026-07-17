`timescale 1ns/1ps

module fixed_abs #(
    parameter WIDTH = 16
)(
    input  signed [WIDTH-1:0] in,
    output signed [WIDTH-1:0] out
);

    generate
        if (WIDTH == 1) begin : gen_width_1
            assign out = 1'b0;
        end else begin : gen_abs
            wire signed [WIDTH-1:0] min_negative;
            wire signed [WIDTH-1:0] max_positive;

            assign min_negative = {1'b1, {WIDTH-1{1'b0}}};
            assign max_positive = {1'b0, {WIDTH-1{1'b1}}};

            assign out = (in == min_negative) ? max_positive :
                         in[WIDTH-1]        ? -in :
                                              in;
        end
    endgenerate

endmodule