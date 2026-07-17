`timescale 1ns/1ps

module conv2d_dot_product #(
    parameter DATA_W      = 8,
    parameter KERNEL_SIZE = 3,
    parameter ACC_W       = 20
) (
    input  [DATA_W*KERNEL_SIZE*KERNEL_SIZE-1:0] window_flat,
    input  [8*KERNEL_SIZE*KERNEL_SIZE-1:0]      coeff_flat,
    output signed [ACC_W-1:0]                   sum
);
    localparam N_TAPS = KERNEL_SIZE * KERNEL_SIZE;

    integer i;

    reg signed [ACC_W-1:0] acc;
    reg [DATA_W-1:0] pix;
    reg signed [7:0] coeff;
    reg signed [DATA_W:0] pix_signed;
    reg signed [DATA_W+8:0] product;

    always @* begin
        acc = {ACC_W{1'b0}};

        for (i = 0; i < N_TAPS; i = i + 1) begin
            pix        = window_flat[DATA_W*i +: DATA_W];
            coeff      = coeff_flat[8*i +: 8];
            pix_signed = $signed({1'b0, pix});
            product    = pix_signed * coeff;
            acc        = acc + {{(ACC_W-(DATA_W+9)){product[DATA_W+8]}}, product};
        end
    end

    assign sum = acc >>> 4;

endmodule