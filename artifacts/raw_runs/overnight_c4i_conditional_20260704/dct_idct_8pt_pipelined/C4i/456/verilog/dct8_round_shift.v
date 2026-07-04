`timescale 1ns/1ps

module dct8_round_shift #(
    parameter ACC_W = 32,
    parameter SHIFT = 14
) (
    input  signed [ACC_W-1:0] in_value,
    output signed [ACC_W-1:0] out_value
);

generate
    if (SHIFT == 0) begin : gen_no_shift
        assign out_value = in_value;
    end else begin : gen_round_shift
        wire signed [ACC_W-1:0] round_const =
            {{(ACC_W-SHIFT){1'b0}}, 1'b1, {(SHIFT-1){1'b0}}};

        assign out_value = (in_value + round_const) >>> SHIFT;
    end
endgenerate

endmodule