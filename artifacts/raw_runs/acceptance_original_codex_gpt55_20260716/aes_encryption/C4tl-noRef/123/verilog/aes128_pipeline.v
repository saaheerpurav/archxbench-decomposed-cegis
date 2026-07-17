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

    wire launch = start & valid_in & (mode == 1'b0);

    reg [127:0] state_pipe [0:10];
    reg [127:0] key_pipe   [0:10];
    reg [10:0]  valid_pipe;

    wire [127:0] next_key   [1:10];
    wire [127:0] round_data [1:10];

    genvar gi;
    generate
        for (gi = 1; gi <= 10; gi = gi + 1) begin : GEN_AES
            aes128_key_expand_round u_key_expand (
                .key_in (key_pipe[gi-1]),
                .rcon   (rcon_for_round(gi[3:0])),
                .key_out(next_key[gi])
            );

            aes128_round u_round (
                .state_in   (state_pipe[gi-1]),
                .round_key  (next_key[gi]),
                .final_round(gi == 10),
                .state_out  (round_data[gi])
            );
        end
    endgenerate

    integer i;

    always @(posedge clk) begin
        if (rst) begin
            for (i = 0; i <= 10; i = i + 1) begin
                state_pipe[i] <= 128'h0;
                key_pipe[i]   <= 128'h0;
            end
            valid_pipe <= 11'h0;
            data_out   <= 128'h0;
            valid_out  <= 1'b0;
            done       <= 1'b0;
        end else begin
            state_pipe[0] <= data_in ^ key_in;
            key_pipe[0]   <= key_in;
            valid_pipe[0] <= launch;

            for (i = 1; i <= 10; i = i + 1) begin
                state_pipe[i] <= round_data[i];
                key_pipe[i]   <= next_key[i];
                valid_pipe[i] <= valid_pipe[i-1];
            end

            data_out  <= state_pipe[10];
            valid_out <= valid_pipe[10];
            done      <= valid_pipe[10];
        end
    end

    function [7:0] rcon_for_round;
        input [3:0] round;
        begin
            case (round)
                4'd1:  rcon_for_round = 8'h01;
                4'd2:  rcon_for_round = 8'h02;
                4'd3:  rcon_for_round = 8'h04;
                4'd4:  rcon_for_round = 8'h08;
                4'd5:  rcon_for_round = 8'h10;
                4'd6:  rcon_for_round = 8'h20;
                4'd7:  rcon_for_round = 8'h40;
                4'd8:  rcon_for_round = 8'h80;
                4'd9:  rcon_for_round = 8'h1b;
                4'd10: rcon_for_round = 8'h36;
                default: rcon_for_round = 8'h00;
            endcase
        end
    endfunction

endmodule