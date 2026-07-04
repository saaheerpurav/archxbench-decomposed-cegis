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

    reg [127:0] state_reg;
    reg [127:0] round_key_reg;
    reg [3:0]   round_reg;
    reg         busy_reg;

    wire [127:0] next_round_key;
    wire [127:0] round_state;
    wire [127:0] final_state;

    aes_key_expand_round u_key_expand (
        .key_in(round_key_reg),
        .round(round_reg),
        .key_out(next_round_key)
    );

    aes_encrypt_round u_round (
        .state_in(state_reg),
        .round_key(next_round_key),
        .state_out(round_state)
    );

    aes_encrypt_final_round u_final_round (
        .state_in(state_reg),
        .round_key(next_round_key),
        .state_out(final_state)
    );

    always @(posedge clk) begin
        if (rst) begin
            data_out      <= 128'b0;
            valid_out     <= 1'b0;
            done          <= 1'b0;
            state_reg     <= 128'b0;
            round_key_reg <= 128'b0;
            round_reg     <= 4'b0;
            busy_reg      <= 1'b0;
        end else begin
            valid_out <= 1'b0;
            done      <= 1'b0;

            if (valid_in && start && !busy_reg && (mode == 1'b0)) begin
                state_reg     <= data_in ^ key_in;
                round_key_reg <= key_in;
                round_reg     <= 4'd1;
                busy_reg      <= 1'b1;
            end else if (busy_reg) begin
                round_key_reg <= next_round_key;

                if (round_reg == 4'd10) begin
                    data_out  <= final_state;
                    valid_out <= 1'b1;
                    done      <= 1'b1;
                    busy_reg  <= 1'b0;
                    round_reg <= 4'b0;
                end else begin
                    state_reg <= round_state;
                    round_reg <= round_reg + 4'd1;
                end
            end
        end
    end

endmodule