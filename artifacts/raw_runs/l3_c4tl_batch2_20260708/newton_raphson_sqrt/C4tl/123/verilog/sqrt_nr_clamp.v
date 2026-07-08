`timescale 1ns/1ps

module sqrt_nr_clamp #(
    parameter IN_WIDTH = 24,
    parameter OUT_WIDTH = 16
)(
    input  [IN_WIDTH-1:0] value_in,
    output reg [OUT_WIDTH-1:0] value_out
);

    always @(*) begin
        if (IN_WIDTH > OUT_WIDTH) begin
            if (|value_in[IN_WIDTH-1:OUT_WIDTH])
                value_out = {OUT_WIDTH{1'b1}};
            else
                value_out = value_in[OUT_WIDTH-1:0];
        end else begin
            value_out = value_in[OUT_WIDTH-1:0];
        end
    end

endmodule