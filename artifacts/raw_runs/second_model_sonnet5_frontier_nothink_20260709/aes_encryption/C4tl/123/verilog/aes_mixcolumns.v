module aes_mixcolumns (
    input  [31:0] col_in,   // one column: {b0,b1,b2,b3} big-endian byte order
    output [31:0] col_out
);
    // Bytes of column, MSB first: b0 b1 b2 b3
    wire [7:0] b0 = col_in[31:24];
    wire [7:0] b1 = col_in[23:16];
    wire [7:0] b2 = col_in[15:8];
    wire [7:0] b3 = col_in[7:0];

    function [7:0] xtime;
        input [7:0] a;
        begin
            xtime = (a[7]) ? ((a << 1) ^ 8'h1b) : (a << 1);
        end
    endfunction

    function [7:0] mul2;
        input [7:0] a;
        begin
            mul2 = xtime(a);
        end
    endfunction

    function [7:0] mul3;
        input [7:0] a;
        begin
            mul3 = xtime(a) ^ a;
        end
    endfunction

    wire [7:0] r0 = mul2(b0) ^ mul3(b1) ^ b2 ^ b3;
    wire [7:0] r1 = b0 ^ mul2(b1) ^ mul3(b2) ^ b3;
    wire [7:0] r2 = b0 ^ b1 ^ mul2(b2) ^ mul3(b3);
    wire [7:0] r3 = mul3(b0) ^ b1 ^ b2 ^ mul2(b3);

    assign col_out = {r0, r1, r2, r3};

endmodule