`timescale 1ns/1ps

module aes_round (
    input  [127:0] state_in,
    input  [127:0] round_key,
    input          final_round,
    output [127:0] state_out
);
    wire [127:0] sub_state;
    wire [127:0] shift_state;
    wire [127:0] mix_state;
    wire [127:0] round_state;

    aes_subbytes u_subbytes (
        .state_in  (state_in),
        .state_out (sub_state)
    );

    aes_shiftrows u_shiftrows (
        .state_in  (sub_state),
        .state_out (shift_state)
    );

    aes_mixcolumns u_mixcolumns (
        .state_in  (shift_state),
        .state_out (mix_state)
    );

    assign round_state = final_round ? shift_state : mix_state;
    assign state_out   = round_state ^ round_key;

endmodule