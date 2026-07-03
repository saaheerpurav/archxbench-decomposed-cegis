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

    wire launch = start & valid_in;

    reg [127:0] state_pipe [0:10];
    reg [127:0] key_pipe   [0:10];
    reg         valid_pipe [0:10];

    wire [127:0] round_state [1:10];
    wire [127:0] round_key   [1:10];

    genvar gi;
    generate
        for (gi = 1; gi <= 10; gi = gi + 1) begin : GEN_AES_ROUNDS
            aes_key_expand u_key_expand (
                .key_in  (key_pipe[gi-1]),
                .round   (gi[3:0]),
                .key_out (round_key[gi])
            );

            aes_round u_round (
                .state_in   (state_pipe[gi-1]),
                .round_key  (round_key[gi]),
                .final_round(gi == 10),
                .state_out  (round_state[gi])
            );
        end
    endgenerate

    integer i;
    always @(posedge clk) begin
        if (rst) begin
            data_out  <= 128'h0;
            valid_out <= 1'b0;
            done      <= 1'b0;
            for (i = 0; i <= 10; i = i + 1) begin
                state_pipe[i] <= 128'h0;
                key_pipe[i]   <= 128'h0;
                valid_pipe[i] <= 1'b0;
            end
        end else begin
            state_pipe[0] <= data_in ^ key_in;
            key_pipe[0]   <= key_in;
            valid_pipe[0] <= launch;

            for (i = 1; i <= 10; i = i + 1) begin
                state_pipe[i] <= round_state[i];
                key_pipe[i]   <= round_key[i];
                valid_pipe[i] <= valid_pipe[i-1];
            end

            data_out  <= round_state[10];
            valid_out <= valid_pipe[9];
            done      <= valid_pipe[9];
        end
    end

endmodule