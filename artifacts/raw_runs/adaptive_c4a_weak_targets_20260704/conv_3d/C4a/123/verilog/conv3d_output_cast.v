`timescale 1ns/1ps

module conv3d_output_cast #(
    parameter IN_W  = 22,
    parameter OUT_W = 12
) (
    input  [IN_W-1:0]  in_value,
    output [OUT_W-1:0] out_value
);

generate
    if (OUT_W <= IN_W) begin : gen_truncate
        assign out_value = in_value[OUT_W-1:0];
    end else begin : gen_extend
        assign out_value = {{(OUT_W-IN_W){1'b0}}, in_value};
    end
endgenerate

endmodule