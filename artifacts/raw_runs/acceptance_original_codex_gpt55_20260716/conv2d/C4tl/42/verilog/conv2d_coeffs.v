`timescale 1ns/1ps

module conv2d_coeffs #(
    parameter KERNEL_SIZE = 3
) (
    output reg [KERNEL_SIZE*KERNEL_SIZE*8-1:0] coeffs
);
    integer i;

    always @* begin
        coeffs = {KERNEL_SIZE*KERNEL_SIZE*8{1'b0}};

        if (KERNEL_SIZE == 3) begin
            coeffs[(0+1)*8-1 -: 8] = 8'd1;
            coeffs[(1+1)*8-1 -: 8] = 8'd2;
            coeffs[(2+1)*8-1 -: 8] = 8'd1;
            coeffs[(3+1)*8-1 -: 8] = 8'd2;
            coeffs[(4+1)*8-1 -: 8] = 8'd4;
            coeffs[(5+1)*8-1 -: 8] = 8'd2;
            coeffs[(6+1)*8-1 -: 8] = 8'd1;
            coeffs[(7+1)*8-1 -: 8] = 8'd2;
            coeffs[(8+1)*8-1 -: 8] = 8'd1;
        end else begin
            for (i = 0; i < KERNEL_SIZE*KERNEL_SIZE; i = i + 1) begin
                if (i == ((KERNEL_SIZE*KERNEL_SIZE)/2))
                    coeffs[(i+1)*8-1 -: 8] = 8'd1;
                else
                    coeffs[(i+1)*8-1 -: 8] = 8'd0;
            end
        end
    end
endmodule