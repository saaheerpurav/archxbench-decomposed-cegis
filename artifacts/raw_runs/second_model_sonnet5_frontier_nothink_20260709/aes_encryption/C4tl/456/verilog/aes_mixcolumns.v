module aes_mixcolumns (
    input  [31:0] col_in,
    output [31:0] col_out
);
    wire [7:0] a0 = col_in[31:24];
    wire [7:0] a1 = col_in[23:16];
    wire [7:0] a2 = col_in[15:8];
    wire [7:0] a3 = col_in[7:0];

    function [7:0] xtime;
        input [7:0] b;
        begin
            xtime = (b[7]) ? ((b << 1) ^ 8'h1b) : (b << 1);
        end
    endfunction

    function [7:0] mul2;
        input [7:0] b;
        begin
            mul2 = xtime(b);
        end
    endfunction

    function [7:0] mul3;
        input [7:0] b;
        begin
            mul3 = xtime(b) ^ b;
        end
    endfunction

    wire [7:0] b0 = mul2(a0) ^ mul3(a1) ^ a2 ^ a3;
    wire [7:0] b1 = a0 ^ mul2(a1) ^ mul3(a2) ^ a3;
    wire [7:0] b2 = a0 ^ a1 ^ mul2(a2) ^ mul3(a3);
    wire [7:0] b3 = mul3(a0) ^ a1 ^ a2 ^ mul2(a3);

    assign col_out = {b0, b1, b2, b3};

endmodule