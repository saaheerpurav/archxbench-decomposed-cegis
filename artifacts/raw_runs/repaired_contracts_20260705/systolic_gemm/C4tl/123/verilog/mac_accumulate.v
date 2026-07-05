module mac_accumulate(acc_in, product, acc_out);
    input [63:0] acc_in;
    input [63:0] product;
    output [63:0] acc_out;

    assign acc_out = acc_in + product;
endmodule