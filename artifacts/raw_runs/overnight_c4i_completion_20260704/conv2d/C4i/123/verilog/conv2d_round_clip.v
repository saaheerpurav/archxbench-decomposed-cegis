`timescale 1ns/1ps

module conv2d_round_clip #(
    parameter IN_W  = 16,
    parameter OUT_W = 12
) (
    input      [IN_W-1:0]   value_in,
    output reg [OUT_W-1:0]  value_out
);

generate
    if (IN_W >= OUT_W) begin : gen_truncate
        always @(*) begin
            value_out = value_in[OUT_W-1:0];
        end
    end else begin : gen_extend
        always @(*) begin
            value_out = {{(OUT_W-IN_W){1'b0}}, value_in};
        end
    end
endgenerate

endmodule