module pe_accumulate(current_result, product, next_result);
    input [63:0] current_result;
    input [63:0] product;
    output [63:0] next_result;

    assign next_result = current_result + product;
endmodule