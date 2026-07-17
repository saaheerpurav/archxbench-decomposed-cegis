`timescale 1ns/1ps

module conv3d_coord_decode #(
    parameter D = 8,
    parameter H = 64,
    parameter W = 64
) (
    input  [clog2(D*H*W+1)-1:0] index,
    output [clog2(D)-1:0]       d_idx,
    output [clog2(H)-1:0]       h_idx,
    output [clog2(W)-1:0]       w_idx
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
            if (clog2 < 1)
                clog2 = 1;
        end
    endfunction

    assign d_idx = index / (H * W);
    assign h_idx = (index / W) % H;
    assign w_idx = index % W;

endmodule