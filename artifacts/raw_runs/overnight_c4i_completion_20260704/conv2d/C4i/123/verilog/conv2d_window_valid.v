`timescale 1ns/1ps

module conv2d_window_valid #(
    parameter KERNEL_SIZE = 3
) (
    input      [31:0] row_count,
    input      [31:0] col_count,
    input             valid_in,
    output reg        window_valid
);

    localparam [31:0] WINDOW_FILL = KERNEL_SIZE - 1;

    always @(*) begin
        window_valid = valid_in ||
                       ((row_count >= WINDOW_FILL) &&
                        (col_count <  WINDOW_FILL));
    end

endmodule