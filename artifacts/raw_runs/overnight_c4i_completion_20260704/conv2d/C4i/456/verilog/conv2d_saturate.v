`timescale 1ns/1ps

module conv2d_saturate #(
    parameter IN_W  = 20,
    parameter OUT_W = 12
) (
    input  signed [IN_W-1:0] value_in,
    output reg [OUT_W-1:0]   value_out
);

generate
    if (OUT_W < IN_W) begin : gen_narrow
        localparam signed [IN_W-1:0] MAX_VALUE =
            {{(IN_W-OUT_W){1'b0}}, {OUT_W{1'b1}}};

        always @(*) begin
            if (value_in < 0)
                value_out = {OUT_W{1'b0}};
            else if (value_in > MAX_VALUE)
                value_out = {OUT_W{1'b1}};
            else
                value_out = value_in[OUT_W-1:0];
        end
    end else begin : gen_wide
        always @(*) begin
            if (value_in < 0)
                value_out = {OUT_W{1'b0}};
            else
                value_out = {{(OUT_W-IN_W){1'b0}}, value_in};
        end
    end
endgenerate

endmodule