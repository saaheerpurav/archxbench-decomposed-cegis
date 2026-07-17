`timescale 1ns/1ps

module aes128_decrypt_core (
    input  [127:0]  ciphertext,
    input  [1407:0] round_keys,
    output [127:0]  plaintext
);
    wire [127:0] rk [0:10];
    wire [127:0] st [0:10];

    genvar i;
    generate
        for (i = 0; i < 11; i = i + 1) begin : unpack_keys
            assign rk[i] = round_keys[i*128 +: 128];
        end
    endgenerate

    assign st[10] = ciphertext ^ rk[10];

    aes128_inv_round r9 (.state_in(st[10]), .round_key(rk[9]), .final_round(1'b0), .state_out(st[9]));
    aes128_inv_round r8 (.state_in(st[9]),  .round_key(rk[8]), .final_round(1'b0), .state_out(st[8]));
    aes128_inv_round r7 (.state_in(st[8]),  .round_key(rk[7]), .final_round(1'b0), .state_out(st[7]));
    aes128_inv_round r6 (.state_in(st[7]),  .round_key(rk[6]), .final_round(1'b0), .state_out(st[6]));
    aes128_inv_round r5 (.state_in(st[6]),  .round_key(rk[5]), .final_round(1'b0), .state_out(st[5]));
    aes128_inv_round r4 (.state_in(st[5]),  .round_key(rk[4]), .final_round(1'b0), .state_out(st[4]));
    aes128_inv_round r3 (.state_in(st[4]),  .round_key(rk[3]), .final_round(1'b0), .state_out(st[3]));
    aes128_inv_round r2 (.state_in(st[3]),  .round_key(rk[2]), .final_round(1'b0), .state_out(st[2]));
    aes128_inv_round r1 (.state_in(st[2]),  .round_key(rk[1]), .final_round(1'b0), .state_out(st[1]));
    aes128_inv_round r0 (.state_in(st[1]),  .round_key(rk[0]), .final_round(1'b1), .state_out(st[0]));

    assign plaintext = st[0];
endmodule