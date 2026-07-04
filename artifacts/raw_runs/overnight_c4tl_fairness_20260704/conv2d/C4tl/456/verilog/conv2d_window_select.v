`timescale 1ns/1ps

module conv2d_window_select #(
    parameter DATA_W = 8,
    parameter ACC_W  = DATA_W + 12
) (
    input      [DATA_W-1:0] p00,
    input      [DATA_W-1:0] p01,
    input      [DATA_W-1:0] p02,
    input      [DATA_W-1:0] p10,
    input      [DATA_W-1:0] p11,
    input      [DATA_W-1:0] p12,
    input      [DATA_W-1:0] p20,
    input      [DATA_W-1:0] p21,
    input      [DATA_W-1:0] p22,
    output     [ACC_W-1:0]  weighted_sum
);
    wire [ACC_W-1:0] w00 = {{(ACC_W-DATA_W){1'b0}}, p00};
    wire [ACC_W-1:0] w01 = {{(ACC_W-DATA_W){1'b0}}, p01} << 1;
    wire [ACC_W-1:0] w02 = {{(ACC_W-DATA_W){1'b0}}, p02};

    wire [ACC_W-1:0] w10 = {{(ACC_W-DATA_W){1'b0}}, p10} << 1;
    wire [ACC_W-1:0] w11 = {{(ACC_W-DATA_W){1'b0}}, p11} << 2;
    wire [ACC_W-1:0] w12 = {{(ACC_W-DATA_W){1'b0}}, p12} << 1;

    wire [ACC_W-1:0] w20 = {{(ACC_W-DATA_W){1'b0}}, p20};
    wire [ACC_W-1:0] w21 = {{(ACC_W-DATA_W){1'b0}}, p21} << 1;
    wire [ACC_W-1:0] w22 = {{(ACC_W-DATA_W){1'b0}}, p22};

    assign weighted_sum = w00 + w01 + w02 +
                          w10 + w11 + w12 +
                          w20 + w21 + w22;

endmodule