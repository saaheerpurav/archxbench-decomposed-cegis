`timescale 1ns/1ps

module conv3d_mac #(
    parameter K1 = 3,
    parameter K2 = 3,
    parameter K3 = 3,
    parameter DATA_W = 8
) (
    input  [DATA_W*K1*K2*K3-1:0] window_flat,
    input  [DATA_W*K1*K2*K3-1:0] kernel,
    output reg [(2*DATA_W)+CLOG2(K1*K2*K3+1)-1:0] sum
);

    function integer CLOG2;
        input integer value;
        integer v;
        begin
            v = value - 1;
            for (CLOG2 = 0; v > 0; CLOG2 = CLOG2 + 1)
                v = v >> 1;
        end
    endfunction

    localparam integer K_TOTAL = K1 * K2 * K3;
    localparam integer SUM_W = (2 * DATA_W) + CLOG2(K_TOTAL + 1);

    integer i;
    reg [DATA_W-1:0] voxel;
    reg [DATA_W-1:0] coeff;
    reg [(2*DATA_W)-1:0] product;

    always @* begin
        sum = {SUM_W{1'b0}};

        for (i = 0; i < K_TOTAL; i = i + 1) begin
            voxel = window_flat[i*DATA_W +: DATA_W];
            coeff = kernel[i*DATA_W +: DATA_W];
            product = voxel * coeff;
            sum = sum + {{(SUM_W-(2*DATA_W)){1'b0}}, product};
        end
    end

endmodule