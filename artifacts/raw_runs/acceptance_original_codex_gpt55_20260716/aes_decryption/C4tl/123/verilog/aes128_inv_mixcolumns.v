`timescale 1ns/1ps

module aes128_inv_mixcolumns (
    input  [127:0] state_in,
    output [127:0] state_out
);

    function [7:0] get_byte;
        input [127:0] s;
        input integer idx;
        begin
            get_byte = s[127 - 8*idx -: 8];
        end
    endfunction

    function [7:0] xtime;
        input [7:0] x;
        begin
            xtime = {x[6:0], 1'b0} ^ (x[7] ? 8'h1b : 8'h00);
        end
    endfunction

    function [7:0] gf_mul_inv_const;
        input [7:0] x;
        input [7:0] c;
        reg [7:0] x2;
        reg [7:0] x4;
        reg [7:0] x8;
        begin
            x2 = xtime(x);
            x4 = xtime(x2);
            x8 = xtime(x4);

            case (c)
                8'h09: gf_mul_inv_const = x8 ^ x;
                8'h0b: gf_mul_inv_const = x8 ^ x2 ^ x;
                8'h0d: gf_mul_inv_const = x8 ^ x4 ^ x;
                8'h0e: gf_mul_inv_const = x8 ^ x4 ^ x2;
                default: gf_mul_inv_const = 8'h00;
            endcase
        end
    endfunction

    function [31:0] inv_mix_column;
        input [31:0] col;
        reg [7:0] s0;
        reg [7:0] s1;
        reg [7:0] s2;
        reg [7:0] s3;
        begin
            s0 = col[31:24];
            s1 = col[23:16];
            s2 = col[15:8];
            s3 = col[7:0];

            inv_mix_column = {
                gf_mul_inv_const(s0, 8'h0e) ^ gf_mul_inv_const(s1, 8'h0b) ^
                gf_mul_inv_const(s2, 8'h0d) ^ gf_mul_inv_const(s3, 8'h09),

                gf_mul_inv_const(s0, 8'h09) ^ gf_mul_inv_const(s1, 8'h0e) ^
                gf_mul_inv_const(s2, 8'h0b) ^ gf_mul_inv_const(s3, 8'h0d),

                gf_mul_inv_const(s0, 8'h0d) ^ gf_mul_inv_const(s1, 8'h09) ^
                gf_mul_inv_const(s2, 8'h0e) ^ gf_mul_inv_const(s3, 8'h0b),

                gf_mul_inv_const(s0, 8'h0b) ^ gf_mul_inv_const(s1, 8'h0d) ^
                gf_mul_inv_const(s2, 8'h09) ^ gf_mul_inv_const(s3, 8'h0e)
            };
        end
    endfunction

    assign state_out = {
        inv_mix_column({get_byte(state_in, 0),  get_byte(state_in, 1),
                        get_byte(state_in, 2),  get_byte(state_in, 3)}),

        inv_mix_column({get_byte(state_in, 4),  get_byte(state_in, 5),
                        get_byte(state_in, 6),  get_byte(state_in, 7)}),

        inv_mix_column({get_byte(state_in, 8),  get_byte(state_in, 9),
                        get_byte(state_in, 10), get_byte(state_in, 11)}),

        inv_mix_column({get_byte(state_in, 12), get_byte(state_in, 13),
                        get_byte(state_in, 14), get_byte(state_in, 15)})
    };

endmodule