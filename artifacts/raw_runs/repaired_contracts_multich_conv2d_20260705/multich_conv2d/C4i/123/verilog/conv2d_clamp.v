`timescale 1ns/1ps

module conv2d_clamp #(
    parameter ACC_W = 40,
    parameter OUT_W = 16
)(
    input signed [ACC_W-1:0] value_in,
    output reg [OUT_W-1:0] value_out
);

    localparam signed [ACC_W-1:0] MAX_OUT =
        {{(ACC_W-OUT_W){1'b0}}, {OUT_W{1'b1}}};

    always @* begin
        if (value_in < 0) begin
            value_out = {OUT_W{1'b0}};
        end else if (value_in > MAX_OUT) begin
            value_out = {OUT_W{1'b1}};
        end else begin
            value_out = value_in[OUT_W-1:0];
        end
    end

endmodule