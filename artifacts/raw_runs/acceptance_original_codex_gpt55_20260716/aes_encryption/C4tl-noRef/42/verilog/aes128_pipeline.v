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

    wire accept = start & valid_in & (mode == 1'b0);

    wire [127:0] init_state_w;
    aes128_initial_add u_initial (
        .data_in(data_in),
        .key_in(key_in),
        .state_out(init_state_w)
    );

    reg [127:0] state_pipe [0:9];
    reg [127:0] key_pipe   [0:9];
    reg [10:0]  valid_pipe;

    wire [127:0] r_state [1:9];
    wire [127:0] r_key   [1:9];

    aes128_round #(.RCON(8'h01)) u_r1 (.state_in(state_pipe[0]), .key_in(key_pipe[0]), .state_out(r_state[1]), .key_out(r_key[1]));
    aes128_round #(.RCON(8'h02)) u_r2 (.state_in(state_pipe[1]), .key_in(key_pipe[1]), .state_out(r_state[2]), .key_out(r_key[2]));
    aes128_round #(.RCON(8'h04)) u_r3 (.state_in(state_pipe[2]), .key_in(key_pipe[2]), .state_out(r_state[3]), .key_out(r_key[3]));
    aes128_round #(.RCON(8'h08)) u_r4 (.state_in(state_pipe[3]), .key_in(key_pipe[3]), .state_out(r_state[4]), .key_out(r_key[4]));
    aes128_round #(.RCON(8'h10)) u_r5 (.state_in(state_pipe[4]), .key_in(key_pipe[4]), .state_out(r_state[5]), .key_out(r_key[5]));
    aes128_round #(.RCON(8'h20)) u_r6 (.state_in(state_pipe[5]), .key_in(key_pipe[5]), .state_out(r_state[6]), .key_out(r_key[6]));
    aes128_round #(.RCON(8'h40)) u_r7 (.state_in(state_pipe[6]), .key_in(key_pipe[6]), .state_out(r_state[7]), .key_out(r_key[7]));
    aes128_round #(.RCON(8'h80)) u_r8 (.state_in(state_pipe[7]), .key_in(key_pipe[7]), .state_out(r_state[8]), .key_out(r_key[8]));
    aes128_round #(.RCON(8'h1b)) u_r9 (.state_in(state_pipe[8]), .key_in(key_pipe[8]), .state_out(r_state[9]), .key_out(r_key[9]));

    wire [127:0] final_state_w;
    wire [127:0] final_key_w;
    aes128_final_round #(.RCON(8'h36)) u_final (
        .state_in(state_pipe[9]),
        .key_in(key_pipe[9]),
        .state_out(final_state_w),
        .key_out(final_key_w)
    );

    integer i;

    always @(posedge clk) begin
        if (rst) begin
            for (i = 0; i < 10; i = i + 1) begin
                state_pipe[i] <= 128'h0;
                key_pipe[i]   <= 128'h0;
            end
            valid_pipe <= 11'h0;
            data_out   <= 128'h0;
            valid_out  <= 1'b0;
            done       <= 1'b0;
        end else begin
            state_pipe[0] <= init_state_w;
            key_pipe[0]   <= key_in;

            state_pipe[1] <= r_state[1]; key_pipe[1] <= r_key[1];
            state_pipe[2] <= r_state[2]; key_pipe[2] <= r_key[2];
            state_pipe[3] <= r_state[3]; key_pipe[3] <= r_key[3];
            state_pipe[4] <= r_state[4]; key_pipe[4] <= r_key[4];
            state_pipe[5] <= r_state[5]; key_pipe[5] <= r_key[5];
            state_pipe[6] <= r_state[6]; key_pipe[6] <= r_key[6];
            state_pipe[7] <= r_state[7]; key_pipe[7] <= r_key[7];
            state_pipe[8] <= r_state[8]; key_pipe[8] <= r_key[8];
            state_pipe[9] <= r_state[9]; key_pipe[9] <= r_key[9];

            data_out   <= final_state_w;
            valid_pipe <= {valid_pipe[9:0], accept};
            valid_out  <= valid_pipe[10];
            done       <= valid_pipe[10];
        end
    end

endmodule