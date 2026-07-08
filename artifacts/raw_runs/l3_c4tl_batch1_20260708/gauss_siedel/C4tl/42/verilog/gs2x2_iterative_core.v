`timescale 1ns/1ps

module gs2x2_iterative_core #(
    parameter DATA_WIDTH = 32,
    parameter FRAC = 16,
    parameter ITERATIONS = 32
)(
    input signed [DATA_WIDTH-1:0] a11,
    input signed [DATA_WIDTH-1:0] a12,
    input signed [DATA_WIDTH-1:0] a21,
    input signed [DATA_WIDTH-1:0] a22,
    input signed [DATA_WIDTH-1:0] b1,
    input signed [DATA_WIDTH-1:0] b2,
    input [DATA_WIDTH-1:0] x1_init,
    input [DATA_WIDTH-1:0] x2_init,
    output reg signed [DATA_WIDTH-1:0] x1,
    output reg signed [DATA_WIDTH-1:0] x2
);

    integer i;
    reg signed [DATA_WIDTH-1:0] cur_x1;
    reg signed [DATA_WIDTH-1:0] cur_x2;
    reg signed [(2*DATA_WIDTH)-1:0] inv_a11;
    reg signed [(2*DATA_WIDTH)-1:0] inv_a22;
    reg signed [(2*DATA_WIDTH)-1:0] product;
    reg signed [(2*DATA_WIDTH)-1:0] residual;
    reg signed [(3*DATA_WIDTH)-1:0] update_wide;

    always @* begin
        cur_x1 = x1_init;
        cur_x2 = x2_init;

        if (a11 != 0)
            inv_a11 = ($signed(1) <<< (2*FRAC)) / a11;
        else
            inv_a11 = 0;

        if (a22 != 0)
            inv_a22 = ($signed(1) <<< (2*FRAC)) / a22;
        else
            inv_a22 = 0;

        for (i = 0; i < ITERATIONS; i = i + 1) begin
            product = a12 * cur_x2;
            residual = {{DATA_WIDTH{b1[DATA_WIDTH-1]}}, b1} - (product >>> FRAC);
            update_wide = residual * inv_a11;
            cur_x1 = update_wide >>> FRAC;

            product = a21 * cur_x1;
            residual = {{DATA_WIDTH{b2[DATA_WIDTH-1]}}, b2} - (product >>> FRAC);
            update_wide = residual * inv_a22;
            cur_x2 = update_wide >>> FRAC;
        end

        x1 = cur_x1;
        x2 = cur_x2;
    end

endmodule