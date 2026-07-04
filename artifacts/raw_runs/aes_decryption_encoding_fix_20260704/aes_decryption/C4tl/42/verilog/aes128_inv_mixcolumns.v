`timescale 1ns/1ps

module aes128_inv_mixcolumns (
    input  [127:0] state_in,
    output [127:0] state_out
);

    function [7:0] xtime;
        input [7:0] x;
        begin
            xtime = {x[6:0], 1'b0} ^ (x[7] ? 8'h1b : 8'h00);
        end
    endfunction

    function [7:0] gf_mul;
        input [7:0] a;
        input [7:0] b;
        reg   [7:0] aa;
        reg   [7:0] bb;
        reg   [7:0] p;
        integer i;
        begin
            aa = a;
            bb = b;
            p  = 8'h00;

            for (i = 0; i < 8; i = i + 1) begin
                if (bb[0])
                    p = p ^ aa;

                aa = xtime(aa);
                bb = bb >> 1;
            end

            gf_mul = p;
        end
    endfunction

    function [7:0] get_byte;
        input [127:0] s;
        input integer idx;
        begin
            get_byte = s[127 - (8 * idx) -: 8];
        end
    endfunction

    genvar c;
    generate
        for (c = 0; c < 4; c = c + 1) begin : gen_inv_mix_col
            wire [7:0] s0;
            wire [7:0] s1;
            wire [7:0] s2;
            wire [7:0] s3;

            assign s0 = get_byte(state_in, (4 * c) + 0);
            assign s1 = get_byte(state_in, (4 * c) + 1);
            assign s2 = get_byte(state_in, (4 * c) + 2);
            assign s3 = get_byte(state_in, (4 * c) + 3);

            assign state_out[127 - (8 * ((4 * c) + 0)) -: 8] =
                gf_mul(s0, 8'h0e) ^ gf_mul(s1, 8'h0b) ^
                gf_mul(s2, 8'h0d) ^ gf_mul(s3, 8'h09);

            assign state_out[127 - (8 * ((4 * c) + 1)) -: 8] =
                gf_mul(s0, 8'h09) ^ gf_mul(s1, 8'h0e) ^
                gf_mul(s2, 8'h0b) ^ gf_mul(s3, 8'h0d);

            assign state_out[127 - (8 * ((4 * c) + 2)) -: 8] =
                gf_mul(s0, 8'h0d) ^ gf_mul(s1, 8'h09) ^
                gf_mul(s2, 8'h0e) ^ gf_mul(s3, 8'h0b);

            assign state_out[127 - (8 * ((4 * c) + 3)) -: 8] =
                gf_mul(s0, 8'h0b) ^ gf_mul(s1, 8'h0d) ^
                gf_mul(s2, 8'h09) ^ gf_mul(s3, 8'h0e);
        end
    endgenerate

endmodule