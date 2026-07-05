`timescale 1ns/1ps

module int_dot_product #(
  parameter K = 64,
  parameter QBW = 8,
  parameter ACC_W = 32
)(
  input  [K*(QBW+1)-1:0] a_vec,
  input  [K*(QBW+1)-1:0] b_vec,
  output reg signed [ACC_W-1:0] acc
);

  localparam ELEM_W = QBW + 1;
  localparam PROD_W = 2 * ELEM_W;

  integer k;

  reg signed [ELEM_W-1:0] a_val;
  reg signed [ELEM_W-1:0] b_val;
  reg signed [PROD_W-1:0] prod;
  reg signed [ACC_W-1:0] sum;

  function signed [ACC_W-1:0] resize_product;
    input signed [PROD_W-1:0] value;
    integer i;
    begin
      for (i = 0; i < ACC_W; i = i + 1) begin
        if (i < PROD_W)
          resize_product[i] = value[i];
        else
          resize_product[i] = value[PROD_W-1];
      end
    end
  endfunction

  always @* begin
    sum = {ACC_W{1'b0}};

    for (k = 0; k < K; k = k + 1) begin
      a_val = $signed(a_vec[k*ELEM_W +: ELEM_W]);
      b_val = $signed(b_vec[k*ELEM_W +: ELEM_W]);
      prod = a_val * b_val;
      sum = sum + resize_product(prod);
    end

    acc = sum;
  end

endmodule