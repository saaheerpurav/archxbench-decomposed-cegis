`timescale 1ns/1ps

module conv2d_saturate #(
    parameter IN_W  = 20,
    parameter OUT_W = 12
) (
    input      [IN_W-1:0]   value_in,
    output reg [OUT_W-1:0]  value_out
);

generate
    if (IN_W > OUT_W) begin : gen_saturating_downsize
        always @* begin
            if (|value_in[IN_W-1:OUT_W])
                value_out = {OUT_W{1'b1}};
            else
                value_out = value_in[OUT_W-1:0];
        end
    end else if (IN_W == OUT_W) begin : gen_passthrough
        always @* begin
            value_out = value_in;
        end
    end else begin : gen_zero_extend
        always @* begin
            value_out = {{(OUT_W-IN_W){1'b0}}, value_in};
        end
    end
endgenerate

endmodule