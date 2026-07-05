`timescale 1ns/1ps

module conv3d_coord_next #(
    parameter D = 8,
    parameter H = 64,
    parameter W = 64
) (
    input  [CLOG2(D*H*W)-1:0] flat_index,
    input  [CLOG2(W)-1:0]     x_pos,
    input  [CLOG2(H)-1:0]     y_pos,
    input  [CLOG2(D)-1:0]     z_pos,
    output reg [CLOG2(D*H*W)-1:0] next_flat_index,
    output reg [CLOG2(W)-1:0]     next_x_pos,
    output reg [CLOG2(H)-1:0]     next_y_pos,
    output reg [CLOG2(D)-1:0]     next_z_pos
);

    function integer CLOG2;
        input integer value;
        integer v;
        begin
            if (value <= 1) begin
                CLOG2 = 1;
            end else begin
                v = value - 1;
                for (CLOG2 = 0; v > 0; CLOG2 = CLOG2 + 1)
                    v = v >> 1;
            end
        end
    endfunction

    always @* begin
        next_flat_index = flat_index + {{(CLOG2(D*H*W)-1){1'b0}}, 1'b1};

        next_x_pos = x_pos;
        next_y_pos = y_pos;
        next_z_pos = z_pos;

        if ((x_pos == W-1) && (y_pos == H-1) && (z_pos == D-1)) begin
            next_flat_index = {CLOG2(D*H*W){1'b0}};
            next_x_pos = {CLOG2(W){1'b0}};
            next_y_pos = {CLOG2(H){1'b0}};
            next_z_pos = {CLOG2(D){1'b0}};
        end else if (x_pos == W-1) begin
            next_x_pos = {CLOG2(W){1'b0}};

            if (y_pos == H-1) begin
                next_y_pos = {CLOG2(H){1'b0}};
                next_z_pos = z_pos + {{(CLOG2(D)-1){1'b0}}, 1'b1};
            end else begin
                next_y_pos = y_pos + {{(CLOG2(H)-1){1'b0}}, 1'b1};
            end
        end else begin
            next_x_pos = x_pos + {{(CLOG2(W)-1){1'b0}}, 1'b1};
        end
    end

endmodule