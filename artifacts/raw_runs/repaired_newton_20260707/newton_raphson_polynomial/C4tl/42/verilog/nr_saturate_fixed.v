`timescale 1ns/1ps

module nr_saturate_fixed #(
    parameter WIDTH = 16,
    parameter WIDE = WIDTH * 4
)(
    input signed [WIDE-1:0] in_value,
    output reg signed [WIDTH-1:0] out_value
);

    wire signed [WIDE-1:0] max_value;
    wire signed [WIDE-1:0] min_value;

    assign max_value = {{(WIDE-WIDTH){1'b0}}, {1'b0, {(WIDTH-1){1'b1}}}};
    assign min_value = {{(WIDE-WIDTH){1'b1}}, {1'b1, {(WIDTH-1){1'b0}}}};

    always @(*) begin
        if (in_value > max_value)
            out_value = {1'b0, {(WIDTH-1){1'b1}}};
        else if (in_value < min_value)
            out_value = {1'b1, {(WIDTH-1){1'b0}}};
        else
            out_value = in_value[WIDTH-1:0];
    end

endmodule