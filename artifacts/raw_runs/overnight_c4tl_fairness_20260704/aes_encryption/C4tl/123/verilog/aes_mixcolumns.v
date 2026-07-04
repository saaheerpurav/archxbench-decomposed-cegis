`timescale 1ns/1ps

module aes_mixcolumns (
    input  [127:0] state_in,
    output [127:0] state_out
);

    function [7:0] xtime;
        input [7:0] x;
        begin
            xtime = {x[6:0], 1'b0} ^ (8'h1b & {8{x[7]}});
        end
    endfunction

    function [31:0] mix_col;
        input [31:0] col;

        reg [7:0] a0;
        reg [7:0] a1;
        reg [7:0] a2;
        reg [7:0] a3;

        reg [7:0] x2_a0;
        reg [7:0] x2_a1;
        reg [7:0] x2_a2;
        reg [7:0] x2_a3;

        reg [7:0] x3_a0;
        reg [7:0] x3_a1;
        reg [7:0] x3_a2;
        reg [7:0] x3_a3;

        begin
            a0 = col[31:24];
            a1 = col[23:16];
            a2 = col[15:8];
            a3 = col[7:0];

            x2_a0 = xtime(a0);
            x2_a1 = xtime(a1);
            x2_a2 = xtime(a2);
            x2_a3 = xtime(a3);

            x3_a0 = x2_a0 ^ a0;
            x3_a1 = x2_a1 ^ a1;
            x3_a2 = x2_a2 ^ a2;
            x3_a3 = x2_a3 ^ a3;

            mix_col[31:24] = x2_a0 ^ x3_a1 ^ a2    ^ a3;
            mix_col[23:16] = a0    ^ x2_a1 ^ x3_a2 ^ a3;
            mix_col[15:8]  = a0    ^ a1    ^ x2_a2 ^ x3_a3;
            mix_col[7:0]   = x3_a0 ^ a1    ^ a2    ^ x2_a3;
        end
    endfunction

    assign state_out[127:96] = mix_col(state_in[127:96]);
    assign state_out[95:64]  = mix_col(state_in[95:64]);
    assign state_out[63:32]  = mix_col(state_in[63:32]);
    assign state_out[31:0]   = mix_col(state_in[31:0]);

endmodule