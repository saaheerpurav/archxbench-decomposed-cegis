`timescale 1ns/1ps

module nr_saturate_signed #(
    parameter IN_WIDTH  = 64,
    parameter OUT_WIDTH = 16
)(
    input  signed [IN_WIDTH-1:0] in_value,
    output reg signed [OUT_WIDTH-1:0] out_value
);

    localparam signed [OUT_WIDTH-1:0] OUT_MAX =
        {1'b0, {(OUT_WIDTH-1){1'b1}}};

    localparam signed [OUT_WIDTH-1:0] OUT_MIN =
        {1'b1, {(OUT_WIDTH-1){1'b0}}};

    wire retained_sign = in_value[OUT_WIDTH-1];
    wire [IN_WIDTH-OUT_WIDTH-1:0] discarded_bits =
        in_value[IN_WIDTH-1:OUT_WIDTH];

    wire positive_overflow =
        (retained_sign == 1'b0) &&
        (discarded_bits != {(IN_WIDTH-OUT_WIDTH){1'b0}});

    wire negative_overflow =
        (retained_sign == 1'b1) &&
        (discarded_bits != {(IN_WIDTH-OUT_WIDTH){1'b1}});

    always @* begin
        if (positive_overflow) begin
            out_value = OUT_MAX;
        end else if (negative_overflow) begin
            out_value = OUT_MIN;
        end else begin
            out_value = in_value[OUT_WIDTH-1:0];
        end
    end

endmodule