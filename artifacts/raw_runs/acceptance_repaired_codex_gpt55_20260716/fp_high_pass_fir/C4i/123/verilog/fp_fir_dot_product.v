`timescale 1ns/1ps

module fp_fir_dot_product #(
    parameter TAP_CNT = 101
) (
    input  wire [32*TAP_CNT-1:0] sample_bus,
    input  wire [32*TAP_CNT-1:0] coeff_bus,
    output wire [31:0] result
);

  wire [31:0] mul_result [0:TAP_CNT-1];
  wire [31:0] add_result [0:TAP_CNT-1];

  genvar gi;
  generate
    for (gi = 0; gi < TAP_CNT; gi = gi + 1) begin : MUL_STAGE
      fp32_mul u_mul (
        .a(sample_bus[32*gi +: 32]),
        .b(coeff_bus[32*gi +: 32]),
        .y(mul_result[gi])
      );
    end

    fp32_add u_add_first (
      .a(32'h00000000),
      .b(mul_result[0]),
      .y(add_result[0])
    );

    for (gi = 1; gi < TAP_CNT; gi = gi + 1) begin : ADD_STAGE
      fp32_add u_add (
        .a(add_result[gi-1]),
        .b(mul_result[gi]),
        .y(add_result[gi])
      );
    end
  endgenerate

  assign result = add_result[TAP_CNT-1];

endmodule