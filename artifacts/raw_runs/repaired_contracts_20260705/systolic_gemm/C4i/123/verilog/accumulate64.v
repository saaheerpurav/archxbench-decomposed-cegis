module accumulate64(acc_in, addend, acc_out);
    input [63:0] acc_in;
    input [63:0] addend;
    output [63:0] acc_out;

    assign acc_out = acc_in + addend;
endmodule