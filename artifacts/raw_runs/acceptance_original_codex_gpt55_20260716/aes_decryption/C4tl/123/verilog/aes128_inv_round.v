`timescale 1ns/1ps

module aes128_inv_round (
    input  [127:0] state_in,
    input  [127:0] round_key,
    input          final_round,
    output [127:0] state_out
);

    wire [127:0] shifted;
    wire [127:0] subbed;
    wire [127:0] keyed;
    wire [127:0] mixed;

    aes128_inv_shiftrows u_shiftrows (
        .state_in  (state_in),
        .state_out (shifted)
    );

    aes128_inv_subbytes u_subbytes (
        .state_in  (shifted),
        .state_out (subbed)
    );

    assign keyed = subbed ^ round_key;

    aes128_inv_mixcolumns u_mixcolumns (
        .state_in  (keyed),
        .state_out (mixed)
    );

    assign state_out = final_round ? keyed : mixed;

endmodule