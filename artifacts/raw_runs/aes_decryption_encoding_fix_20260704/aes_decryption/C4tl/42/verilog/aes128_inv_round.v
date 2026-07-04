`timescale 1ns/1ps

module aes128_inv_round (
    input  [127:0] state_in,
    input  [127:0] round_key,
    input          final_round,
    output [127:0] state_out
);

    wire [127:0] shifted_state;
    wire [127:0] substituted_state;
    wire [127:0] keyed_state;
    wire [127:0] mixed_state;

    aes128_inv_shiftrows u_inv_shiftrows (
        .state_in  (state_in),
        .state_out (shifted_state)
    );

    aes128_inv_subbytes u_inv_subbytes (
        .state_in  (shifted_state),
        .state_out (substituted_state)
    );

    assign keyed_state = substituted_state ^ round_key;

    aes128_inv_mixcolumns u_inv_mixcolumns (
        .state_in  (keyed_state),
        .state_out (mixed_state)
    );

    assign state_out = final_round ? keyed_state : mixed_state;

endmodule