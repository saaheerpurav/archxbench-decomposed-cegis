module pe_accumulate_next(accum_in, product, accum_out);
    input [63:0] accum_in;
    input [63:0] product;
    output [63:0] accum_out;

    assign accum_out = accum_in + product;
endmodule