`timescale 1ns/1ps

module aes128_pipeline #(
    parameter PIPELINED      = 1,
    parameter UNROLL         = 1,
    parameter INLINE_KEY_EXP = 1
) (
    input              clk,
    input              rst,
    input              start,
    input              mode,
    input      [127:0] data_in,
    input      [127:0] key_in,
    input              valid_in,
    output reg [127:0] data_out,
    output reg         valid_out,
    output reg         done
);

    wire [1407:0] round_keys;
    wire [127:0]  s0;
    wire [127:0]  s1;
    wire [127:0]  s2;
    wire [127:0]  s3;
    wire [127:0]  s4;
    wire [127:0]  s5;
    wire [127:0]  s6;
    wire [127:0]  s7;
    wire [127:0]  s8;
    wire [127:0]  s9;
    wire [127:0]  plaintext;

    aes128_key_expand u_key_expand (
        .key_in(key_in),
        .round_keys(round_keys)
    );

    aes128_add_round_key u_initial_add (
        .state_in(data_in),
        .round_key(round_keys[127:0]),
        .state_out(s0)
    );

    aes128_inv_round u_round9 (
        .state_in(s0),
        .round_key(round_keys[255:128]),
        .state_out(s1)
    );

    aes128_inv_round u_round8 (
        .state_in(s1),
        .round_key(round_keys[383:256]),
        .state_out(s2)
    );

    aes128_inv_round u_round7 (
        .state_in(s2),
        .round_key(round_keys[511:384]),
        .state_out(s3)
    );

    aes128_inv_round u_round6 (
        .state_in(s3),
        .round_key(round_keys[639:512]),
        .state_out(s4)
    );

    aes128_inv_round u_round5 (
        .state_in(s4),
        .round_key(round_keys[767:640]),
        .state_out(s5)
    );

    aes128_inv_round u_round4 (
        .state_in(s5),
        .round_key(round_keys[895:768]),
        .state_out(s6)
    );

    aes128_inv_round u_round3 (
        .state_in(s6),
        .round_key(round_keys[1023:896]),
        .state_out(s7)
    );

    aes128_inv_round u_round2 (
        .state_in(s7),
        .round_key(round_keys[1151:1024]),
        .state_out(s8)
    );

    aes128_inv_round u_round1 (
        .state_in(s8),
        .round_key(round_keys[1279:1152]),
        .state_out(s9)
    );

    aes128_inv_final_round u_final (
        .state_in(s9),
        .round_key(round_keys[1407:1280]),
        .state_out(plaintext)
    );

    always @(posedge clk) begin
        if (rst) begin
            data_out  <= 128'b0;
            valid_out <= 1'b0;
            done      <= 1'b0;
        end else begin
            valid_out <= start & valid_in & mode;
            done      <= start & valid_in & mode;
            if (start & valid_in & mode)
                data_out <= plaintext;
        end
    end

endmodule