module pe_compute(west_in, north_in, accum_in, east_out, south_out, accum_out);
    input [31:0] west_in;
    input [31:0] north_in;
    input [63:0] accum_in;
    output [31:0] east_out;
    output [31:0] south_out;
    output [63:0] accum_out;

    wire signed [63:0] west_ext;
    wire signed [63:0] north_ext;
    wire signed [63:0] product;

    assign west_ext = {{32{west_in[31]}}, west_in};
    assign north_ext = {{32{north_in[31]}}, north_in};
    assign product = west_ext * north_ext;

    assign east_out = west_in;
    assign south_out = north_in;
    assign accum_out = $signed(accum_in) + product;
endmodule