`timescale 1ns/1ps

module conv1d_coeff_rom #(
    parameter KERNEL_SIZE = 5,
    parameter COEFF_W     = 8
) (
    output [COEFF_W*KERNEL_SIZE-1:0] coeffs_flat
);

    function [COEFF_W-1:0] coeff_value;
        input integer tap;
        begin
            coeff_value = {COEFF_W{1'b0}};

            case (KERNEL_SIZE)
                3: begin
                    case (tap)
                        0: coeff_value = {{(COEFF_W-1){1'b0}}, 1'd1};
                        1: coeff_value = {{(COEFF_W-2){1'b0}}, 2'd2};
                        2: coeff_value = {{(COEFF_W-1){1'b0}}, 1'd1};
                        default: coeff_value = {COEFF_W{1'b0}};
                    endcase
                end

                5: begin
                    case (tap)
                        0: coeff_value = {{(COEFF_W-2){1'b0}}, 2'd2};
                        1: coeff_value = {{(COEFF_W-4){1'b0}}, 4'd8};
                        2: coeff_value = {{(COEFF_W-4){1'b0}}, 4'd12};
                        3: coeff_value = {{(COEFF_W-4){1'b0}}, 4'd8};
                        4: coeff_value = {{(COEFF_W-2){1'b0}}, 2'd2};
                        default: coeff_value = {COEFF_W{1'b0}};
                    endcase
                end

                7: begin
                    case (tap)
                        0: coeff_value = {{(COEFF_W-1){1'b0}}, 1'd1};
                        1: coeff_value = {{(COEFF_W-3){1'b0}}, 3'd6};
                        2: coeff_value = {{(COEFF_W-4){1'b0}}, 4'd15};
                        3: coeff_value = {{(COEFF_W-5){1'b0}}, 5'd20};
                        4: coeff_value = {{(COEFF_W-4){1'b0}}, 4'd15};
                        5: coeff_value = {{(COEFF_W-3){1'b0}}, 3'd6};
                        6: coeff_value = {{(COEFF_W-1){1'b0}}, 1'd1};
                        default: coeff_value = {COEFF_W{1'b0}};
                    endcase
                end

                default: begin
                    coeff_value = {COEFF_W{1'b0}};
                end
            endcase
        end
    endfunction

    genvar i;
    generate
        for (i = 0; i < KERNEL_SIZE; i = i + 1) begin : gen_coeffs
            assign coeffs_flat[COEFF_W*i +: COEFF_W] = coeff_value(i);
        end
    endgenerate

endmodule