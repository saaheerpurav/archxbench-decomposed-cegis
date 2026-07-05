`timescale 1ns/1ps

module conv3d_window_valid #(
    parameter K1 = 3,
    parameter K2 = 3,
    parameter K3 = 3,
    parameter D = 8,
    parameter H = 64,
    parameter W = 64
) (
    input [clog2(W)-1:0] x_pos,
    input [clog2(H)-1:0] y_pos,
    input [clog2(D)-1:0] z_pos,
    output valid_window
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

    assign valid_window = (x_pos >= K3 - 1) &&
                          (y_pos >= K2 - 1) &&
                          (z_pos >= K1 - 1);

endmodule