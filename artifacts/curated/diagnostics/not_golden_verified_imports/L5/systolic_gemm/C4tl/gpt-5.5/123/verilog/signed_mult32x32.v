module signed_mult32x32(a, b, product);
    input [31:0] a;
    input [31:0] b;
    output [63:0] product;

    assign product = $signed(a) * $signed(b);
endmodule