`timescale 1ns/1ps

module conv3d_window_valid #(
    parameter K1 = 3,
    parameter K2 = 3,
    parameter K3 = 3,
    parameter D = 8,
    parameter H = 64,
    parameter W = 64
) (
    input  [CLOG2(W)-1:0] x_pos,
    input  [CLOG2(H)-1:0] y_pos,
    input  [CLOG2(D)-1:0] z_pos,
    input                 valid_in,
    output                valid_window
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

    assign valid_window = valid_in &&
                          (x_pos >= (K3 - 1)) &&
                          (y_pos >= (K2 - 1)) &&
                          (z_pos >= (K1 - 1));

endmodule