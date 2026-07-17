`timescale 1ns/1ps

module conv3d_window_valid #(
    parameter K1 = 3,
    parameter K2 = 3,
    parameter K3 = 3,
    parameter D  = 8,
    parameter H  = 64,
    parameter W  = 64
) (
    input  [clog2(D)-1:0] d_idx,
    input  [clog2(H)-1:0] h_idx,
    input  [clog2(W)-1:0] w_idx,
    output valid
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

    assign valid =
        (K1 <= D) && (K2 <= H) && (K3 <= W) &&
        (d_idx >= (K1 - 1)) &&
        (h_idx >= (K2 - 1)) &&
        (w_idx >= (K3 - 1));

endmodule