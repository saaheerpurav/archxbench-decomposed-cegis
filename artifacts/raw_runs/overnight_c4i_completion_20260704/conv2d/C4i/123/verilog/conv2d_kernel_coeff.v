`timescale 1ns/1ps

module conv2d_kernel_coeff #(
    parameter KERNEL_SIZE = 3,
    parameter COEFF_W     = 8
) (
    input      [31:0]          index,
    output reg [COEFF_W-1:0]   coeff
);

    localparam integer CENTER_INDEX = (KERNEL_SIZE * KERNEL_SIZE) / 2;

    always @(*) begin
        coeff = {COEFF_W{1'b0}};

        if (KERNEL_SIZE == 3) begin
            case (index)
                32'd4:   coeff = {{(COEFF_W-1){1'b0}}, 1'b1};
                default: coeff = {COEFF_W{1'b0}};
            endcase
        end else begin
            if (index == CENTER_INDEX[31:0])
                coeff = {{(COEFF_W-1){1'b0}}, 1'b1};
            else
                coeff = {COEFF_W{1'b0}};
        end
    end

endmodule