module aes128_final_round (
    input  [127:0] state_in,
    input  [127:0] round_key,
    output [127:0] state_out
);

    wire [127:0] subbytes_shiftrows_state;

    aes128_subbytes_shiftrows u_subbytes_shiftrows (
        .state_in  (state_in),
        .state_out (subbytes_shiftrows_state)
    );

    assign state_out = subbytes_shiftrows_state ^ round_key;

endmodule