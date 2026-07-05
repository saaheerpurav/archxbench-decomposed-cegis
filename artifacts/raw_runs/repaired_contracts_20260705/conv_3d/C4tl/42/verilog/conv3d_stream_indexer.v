`timescale 1ns/1ps

module conv3d_stream_indexer #(
    parameter D = 8,
    parameter H = 64,
    parameter W = 64
) (
    input [clog2(D*H*W+1)-1:0] linear_idx,
    output [clog2(W)-1:0] x_pos,
    output [clog2(H)-1:0] y_pos,
    output [clog2(D)-1:0] z_pos
);

    function integer clog2;
        input integer value;
        integer i;
        begin
            value = value - 1;
            for (i = 0; value > 0; i = i + 1)
                value = value >> 1;
            clog2 = (i == 0) ? 1 : i;
        end
    endfunction

    assign x_pos = linear_idx % W;
    assign y_pos = (linear_idx / W) % H;
    assign z_pos = linear_idx / (W * H);

endmodule