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

    wire accept;
    wire [1407:0] round_keys;
    wire [127:0] plaintext;

    aes128_input_gate u_input_gate (
        .start(start),
        .valid_in(valid_in),
        .mode(mode),
        .accept(accept)
    );

    aes128_key_expand u_key_expand (
        .key_in(key_in),
        .round_keys(round_keys)
    );

    aes128_decrypt_core u_decrypt_core (
        .ciphertext(data_in),
        .round_keys(round_keys),
        .plaintext(plaintext)
    );

    always @(posedge clk) begin
        if (rst) begin
            data_out  <= 128'b0;
            valid_out <= 1'b0;
            done      <= 1'b0;
        end else begin
            valid_out <= accept;
            done      <= accept;
            if (accept)
                data_out <= plaintext;
        end
    end

endmodule