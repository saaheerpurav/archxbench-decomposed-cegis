module mac_cell(a_in, b_in, product);
    input [31:0] a_in;
    input [31:0] b_in;
    output [63:0] product;

    assign product = $signed(a_in) * $signed(b_in);
endmodule