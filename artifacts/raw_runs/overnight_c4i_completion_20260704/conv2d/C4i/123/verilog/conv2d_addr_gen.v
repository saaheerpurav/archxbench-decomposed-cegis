`timescale 1ns/1ps

module conv2d_addr_gen #(
    parameter IMG_WIDTH = 64
) (
    input      [CLOG2(IMG_WIDTH)-1:0] col_in,
    output reg [CLOG2(IMG_WIDTH)-1:0] next_col,
    output reg                        end_of_line
);

    function integer CLOG2;
        input integer value;
        integer i;
        begin
            CLOG2 = 0;
            for (i = value - 1; i > 0; i = i >> 1)
                CLOG2 = CLOG2 + 1;
        end
    endfunction

    always @(*) begin
        end_of_line = (col_in == IMG_WIDTH - 1);

        if (end_of_line)
            next_col = {CLOG2(IMG_WIDTH){1'b0}};
        else
            next_col = col_in + 1'b1;
    end

endmodule