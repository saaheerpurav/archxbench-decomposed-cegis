`timescale 1ns/1ps

module dct1d_8_saturate #(
    parameter IN_W = 36,
    parameter OUT_W = 18
) (
    input signed [IN_W-1:0] in_val,
    output reg signed [OUT_W-1:0] out_val
);

    localparam signed [IN_W-1:0] MAX_OUT = ({{(IN_W-OUT_W+1){1'b0}}, {(OUT_W-1){1'b1}}});
    localparam signed [IN_W-1:0] MIN_OUT = -({{(IN_W-OUT_W+1){1'b0}}, 1'b1, {(OUT_W-1){1'b0}}});

    always @(*) begin
        if (in_val > MAX_OUT)
            out_val = {1'b0, {(OUT_W-1){1'b1}}};
        else if (in_val < MIN_OUT)
            out_val = {1'b1, {(OUT_W-1){1'b0}}};
        else
            out_val = in_val[OUT_W-1:0];
    end

endmodule