`timescale 1ns/1ps

module aes_mixcolumns (
    input  [127:0] state_in,
    output [127:0] state_out
);

    function [7:0] xtime;
        input [7:0] b;
        begin
            xtime = {b[6:0], 1'b0} ^ (8'h1b & {8{b[7]}});
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

    function [31:0] mix_col;
        input [31:0] c;
        reg [7:0] a0;
        reg [7:0] a1;
        reg [7:0] a2;
        reg [7:0] a3;
        begin
            a0 = c[31:24];
            a1 = c[23:16];
            a2 = c[15:8];
            a3 = c[7:0];

            mix_col = {
                mul2(a0) ^ mul3(a1) ^ a2      ^ a3,
                a0      ^ mul2(a1) ^ mul3(a2) ^ a3,
                a0      ^ a1      ^ mul2(a2) ^ mul3(a3),
                mul3(a0) ^ a1      ^ a2      ^ mul2(a3)
            };
        end
    endfunction

    assign state_out[127:96] = mix_col(state_in[127:96]);
    assign state_out[95:64]  = mix_col(state_in[95:64]);
    assign state_out[63:32]  = mix_col(state_in[63:32]);
    assign state_out[31:0]   = mix_col(state_in[31:0]);

endmodule