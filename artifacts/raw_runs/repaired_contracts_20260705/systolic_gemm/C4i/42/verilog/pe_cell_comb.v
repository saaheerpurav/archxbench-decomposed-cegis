module pe_cell_comb(north_in, west_in, accum_in, south_out, east_out, accum_out);
    input [31:0] north_in, west_in;
    input [63:0] accum_in;
    output [31:0] south_out, east_out;
    output [63:0] accum_out;

    wire signed [31:0] north_signed;
    wire signed [31:0] west_signed;
    wire signed [63:0] accum_signed;
    wire signed [63:0] product_signed;

    assign north_signed = north_in;
    assign west_signed = west_in;
    assign accum_signed = accum_in;
    assign product_signed = north_signed * west_signed;

    assign south_out = north_in;
    assign east_out = west_in;
    assign accum_out = accum_signed + product_signed;
endmodule