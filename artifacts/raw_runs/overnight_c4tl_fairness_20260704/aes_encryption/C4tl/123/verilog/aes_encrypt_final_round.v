`timescale 1ns/1ps

module aes_encrypt_final_round (
    input  wire [127:0] state_in,
    input  wire [127:0] round_key,
    output wire [127:0] state_out
);

    wire [127:0] sub_state;
    wire [127:0] shift_state;

    aes_subbytes u_subbytes (
        .state_in  (state_in),
        .state_out (sub_state)
    );

    aes_shiftrows u_shiftrows (
        .state_in  (sub_state),
        .state_out (shift_state)
    );

    assign state_out = shift_state ^ round_key;

endmodule