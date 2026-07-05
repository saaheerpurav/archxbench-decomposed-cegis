module pe_product(west_in, north_in, product);
    input [31:0] west_in;
    input [31:0] north_in;
    output [63:0] product;

    assign product = $signed(west_in) * $signed(north_in);
endmodule