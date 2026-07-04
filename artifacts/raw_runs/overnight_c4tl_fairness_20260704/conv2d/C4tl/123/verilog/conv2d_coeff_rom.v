`timescale 1ns/1ps

module conv2d_coeff_rom #(
    parameter KERNEL_SIZE = 3,
    parameter COEFF_W     = 4
) (
    output reg [KERNEL_SIZE*KERNEL_SIZE*COEFF_W-1:0] coeffs
);

    integer r, c;
    integer idx;
    reg [COEFF_W-1:0] coeff;

    always @* begin
        coeffs = {KERNEL_SIZE*KERNEL_SIZE*COEFF_W{1'b0}};

        for (r = 0; r < KERNEL_SIZE; r = r + 1) begin
            for (c = 0; c < KERNEL_SIZE; c = c + 1) begin
                idx = r*KERNEL_SIZE + c;
                coeff = {{(COEFF_W-1){1'b0}}, 1'b1};

                if (KERNEL_SIZE == 3) begin
                    if (r == 1 && c == 1)
                        coeff = {{(COEFF_W-3){1'b0}}, 3'd4};
                    else if (r == 1 || c == 1)
                        coeff = {{(COEFF_W-2){1'b0}}, 2'd2};
                    else
                        coeff = {{(COEFF_W-1){1'b0}}, 1'b1};
                end

                coeffs[(idx+1)*COEFF_W-1 -: COEFF_W] = coeff;
            end
        end
    end

endmodule