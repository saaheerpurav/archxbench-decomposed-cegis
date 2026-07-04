`timescale 1ns/1ps

module conv3d_mac #(
    parameter K1 = 3,
    parameter K2 = 3,
    parameter K3 = 3,
    parameter DATA_W = 8,
    parameter OUT_W = 12
) (
    input  [K1*K2*K3*DATA_W-1:0] window,
    input  [K1*K2*K3*DATA_W-1:0] kernel,
    output [OUT_W-1:0] result
);

    function integer clog2;
        input integer value;
        integer v;
        begin
            v = value - 1;
            clog2 = 0;
            while (v > 0) begin
                v = v >> 1;
                clog2 = clog2 + 1;
            end
        end
    endfunction

    localparam TERMS = K1 * K2 * K3;
    localparam SUM_W = (2 * DATA_W) + clog2(TERMS);
    localparam ACC_W = (SUM_W > OUT_W) ? SUM_W : OUT_W;

    integer i;
    reg [ACC_W-1:0] acc;
    reg [DATA_W-1:0] voxel;
    reg [DATA_W-1:0] coeff;

    always @* begin
        acc = {ACC_W{1'b0}};

        for (i = 0; i < TERMS; i = i + 1) begin
            voxel = window[i*DATA_W +: DATA_W];
            coeff = kernel[i*DATA_W +: DATA_W];
            acc = acc + (voxel * coeff);
        end
    end

    assign result = acc[OUT_W-1:0];

endmodule