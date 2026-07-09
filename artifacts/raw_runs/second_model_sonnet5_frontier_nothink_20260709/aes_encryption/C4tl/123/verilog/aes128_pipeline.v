module aes128_pipeline #(
    parameter PIPELINED      = 1,
    parameter UNROLL         = 1,
    parameter INLINE_KEY_EXP = 1
) (
    input              clk,
    input              rst,
    input              start,
    input              mode,         // fixed to 1'b0 for encryption
    input      [127:0] data_in,
    input      [127:0] key_in,
    input              valid_in,
    output reg [127:0] data_out,
    output reg         valid_out,
    output reg         done
);

    // Round constants for key expansion, indexed 1..10
    function [7:0] rcon_val;
        input [3:0] r;
        begin
            case (r)
                4'd1:  rcon_val = 8'h01;
                4'd2:  rcon_val = 8'h02;
                4'd3:  rcon_val = 8'h04;
                4'd4:  rcon_val = 8'h08;
                4'd5:  rcon_val = 8'h10;
                4'd6:  rcon_val = 8'h20;
                4'd7:  rcon_val = 8'h40;
                4'd8:  rcon_val = 8'h80;
                4'd9:  rcon_val = 8'h1b;
                4'd10: rcon_val = 8'h36;
                default: rcon_val = 8'h00;
            endcase
        end
    endfunction

    // Pipeline stage storage: state[0] = after AddRoundKey0 (input to round1)
    // key[0] = round key 0 (initial key)
    reg [127:0] state_pipe [0:10];
    reg [127:0] key_pipe   [0:10];
    reg         valid_pipe [0:10];

    wire [127:0] state_next [0:9]; // output of round stage i+1 (rounds 1..10)
    wire [127:0] key_next   [0:9]; // key for stage i+1 (round key i+1)

    genvar gi;
    generate
        for (gi = 0; gi < 10; gi = gi + 1) begin : ROUND_STAGES
            wire is_final = (gi == 9) ? 1'b1 : 1'b0;

            aes_round u_round (
                .state_in (state_pipe[gi]),
                .round_key(key_pipe[gi+1]), // uses next round key (round gi+1)
                .final_round(is_final),
                .state_out(state_next[gi])
            );

            aes_key_expand_round u_keyexp (
                .key_in (key_pipe[gi]),
                .rcon   (rcon_val(gi+1)),
                .key_out(key_next[gi])
            );
        end
    endgenerate

    integer i;
    always @(posedge clk) begin
        if (rst) begin
            for (i = 0; i <= 10; i = i + 1) begin
                state_pipe[i] <= 128'b0;
                key_pipe[i]   <= 128'b0;
                valid_pipe[i] <= 1'b0;
            end
            data_out  <= 128'b0;
            valid_out <= 1'b0;
            done      <= 1'b0;
        end else begin
            // Stage 0: input + AddRoundKey with initial key
            if (valid_in && start) begin
                state_pipe[0] <= data_in ^ key_in;
                key_pipe[0]   <= key_in;
                valid_pipe[0] <= 1'b1;
            end else begin
                valid_pipe[0] <= 1'b0;
            end

            // Stages 1..10: propagate round results
            for (i = 0; i < 10; i = i + 1) begin
                state_pipe[i+1] <= state_next[i];
                key_pipe[i+1]   <= key_next[i];
                valid_pipe[i+1] <= valid_pipe[i];
            end

            // Output
            data_out  <= state_pipe[10];
            valid_out <= valid_pipe[10];
            done      <= valid_pipe[10];
        end
    end

endmodule