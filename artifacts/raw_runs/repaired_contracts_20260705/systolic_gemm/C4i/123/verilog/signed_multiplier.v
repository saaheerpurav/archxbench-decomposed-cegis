module signed_multiplier(a, b, product);
    input [31:0] a, b;
    output [63:0] product;

    assign product = $signed(a) * $signed(b);
endmodule