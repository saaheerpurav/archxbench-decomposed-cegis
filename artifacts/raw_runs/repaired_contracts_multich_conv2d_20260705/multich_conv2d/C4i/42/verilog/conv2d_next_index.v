`timescale 1ns/1ps

module conv2d_next_index #(
    parameter COUT = 8,
    parameter OH = 62,
    parameter OW = 62
)(
    input  [31:0] cur_ch,
    input  [31:0] cur_row,
    input  [31:0] cur_col,
    output reg [31:0] next_ch,
    output reg [31:0] next_row,
    output reg [31:0] next_col,
    output last
);

    assign last = (cur_ch  == COUT - 1) &&
                  (cur_row == OH   - 1) &&
                  (cur_col == OW   - 1);

    always @* begin
        next_ch  = cur_ch;
        next_row = cur_row;
        next_col = cur_col;

        if (cur_col == OW - 1) begin
            next_col = 32'd0;

            if (cur_row == OH - 1) begin
                next_row = 32'd0;

                if (cur_ch == COUT - 1)
                    next_ch = 32'd0;
                else
                    next_ch = cur_ch + 32'd1;
            end else begin
                next_row = cur_row + 32'd1;
            end
        end else begin
            next_col = cur_col + 32'd1;
        end
    end

endmodule