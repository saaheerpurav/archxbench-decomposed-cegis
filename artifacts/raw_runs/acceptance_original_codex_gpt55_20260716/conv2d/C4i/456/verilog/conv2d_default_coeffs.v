`timescale 1ns/1ps

module conv2d_default_coeffs #(
    parameter KERNEL_SIZE = 3,
    parameter COEFF_W = 8
) (
    output [(KERNEL_SIZE*KERNEL_SIZE*COEFF_W)-1:0] coeffs_flat
);

    genvar r;
    genvar c;

    generate
        for (r = 0; r < KERNEL_SIZE; r = r + 1) begin : gen_rows
            for (c = 0; c < KERNEL_SIZE; c = c + 1) begin : gen_cols
                localparam integer IDX = r * KERNEL_SIZE + c;

                if (KERNEL_SIZE == 3) begin : gen_gaussian
                    if ((r == 1) && (c == 1)) begin : gen_center
                        assign coeffs_flat[(IDX * COEFF_W) +: COEFF_W] = 4;
                    end else if ((r == 1) || (c == 1)) begin : gen_axis
                        assign coeffs_flat[(IDX * COEFF_W) +: COEFF_W] = 2;
                    end else begin : gen_corner
                        assign coeffs_flat[(IDX * COEFF_W) +: COEFF_W] = 1;
                    end
                end else begin : gen_identity
                    if ((r == (KERNEL_SIZE / 2)) && (c == (KERNEL_SIZE / 2))) begin : gen_id_center
                        assign coeffs_flat[(IDX * COEFF_W) +: COEFF_W] = 1;
                    end else begin : gen_id_zero
                        assign coeffs_flat[(IDX * COEFF_W) +: COEFF_W] = 0;
                    end
                end
            end
        end
    endgenerate

endmodule