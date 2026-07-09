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

    // Compute all 11 round keys combinationally from key_in
    wire [127:0] round_key [0:10];

    assign round_key[0] = key_in;

    genvar gk;
    generate
        for (gk = 1; gk <= 10; gk = gk + 1) begin : keyexp
            wire [7:0] rcon_val;
            aes_rcon rcon_inst (
                .round_idx(gk[3:0]),
                .rcon(rcon_val)
            );
            aes_key_expand_round key_round_inst (
                .prev_key(round_key[gk-1]),
                .rcon(rcon_val),
                .next_key(round_key[gk])
            );
        end
    endgenerate

    // Pipeline registers: 10 stages, one per AES round
    reg [127:0] stage_data   [0:10];
    reg         stage_valid  [0:10];
    reg [127:0] stage_key    [0:10][0:10]; // not used fully - we store only needed keys per stage

    // Instead of storing all keys per stage, store round keys as constant array
    // and just pipe data + valid through 10 stages, applying round r at stage r.

    wire [127:0] round_out [1:10];

    genvar gr;
    generate
        for (gr = 1; gr <= 10; gr = gr + 1) begin : rounds
            aes_round_func #(
                .IS_LAST(gr == 10)
            ) round_inst (
                .data_in(stage_data[gr-1]),
                .round_key(round_key[gr]),
                .data_out(round_out[gr])
            );
        end
    endgenerate

    integer i;

    always @(posedge clk) begin
        if (rst) begin
            for (i = 0; i <= 10; i = i + 1) begin
                stage_data[i]  <= 128'b0;
                stage_valid[i] <= 1'b0;
            end
            data_out  <= 128'b0;
            valid_out <= 1'b0;
            done      <= 1'b0;
        end else begin
            // Stage 0: input capture
            stage_data[0]  <= data_in ^ round_key[0];
            stage_valid[0] <= (valid_in && start);

            // Stages 1..10: apply round function output
            for (i = 1; i <= 10; i = i + 1) begin
                stage_data[i]  <= round_out[i];
                stage_valid[i] <= stage_valid[i-1];
            end

            data_out  <= stage_data[10];
            valid_out <= stage_valid[10];
            done      <= stage_valid[10];
        end
    end

endmodule

module aes_rcon (
    input  [3:0] round_idx,
    output [7:0] rcon
);
    reg [7:0] rcon_r;
    always @(*) begin
        case (round_idx)
            4'd1:  rcon_r = 8'h01;
            4'd2:  rcon_r = 8'h02;
            4'd3:  rcon_r = 8'h04;
            4'd4:  rcon_r = 8'h08;
            4'd5:  rcon_r = 8'h10;
            4'd6:  rcon_r = 8'h20;
            4'd7:  rcon_r = 8'h40;
            4'd8:  rcon_r = 8'h80;
            4'd9:  rcon_r = 8'h1b;
            4'd10: rcon_r = 8'h36;
            default: rcon_r = 8'h00;
        endcase
    end
    assign rcon = rcon_r;
endmodule