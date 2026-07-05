module pe_forward(west_in, north_in, east_out, south_out);
    input [31:0] west_in;
    input [31:0] north_in;
    output [31:0] east_out;
    output [31:0] south_out;

    assign east_out = west_in;
    assign south_out = north_in;
endmodule