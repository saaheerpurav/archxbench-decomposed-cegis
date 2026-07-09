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

    // Pipeline: stage 0 = initial AddRoundKey, stages 1..10 = rounds 1..10
    // Total 11 stages -> data_pipe[0..10], key_pipe[0..10]
    localparam NSTAGES = 11;

    reg [127:0] data_pipe [0:NSTAGES-1];
    reg [127:0] key_pipe  [0:NSTAGES-1];
    reg         valid_pipe[0:NSTAGES-1];

    wire [127:0] init_data;
    assign init_data = data_in ^ key_in;

    integer i;

    // Key expansion wires for each stage transition (produce next round key)
    wire [127:0] next_key [0:NSTAGES-2];
    wire [127:0] round_out [0:NSTAGES-2];

    genvar g;
    generate
        for (g = 0; g < NSTAGES-1; g = g + 1) begin : GEN_STAGES
            aes_key_expand_round key_exp_inst (
                .round_key_in (key_pipe[g]),
                .round_idx    (g[3:0] + 4'd1),
                .round_key_out(next_key[g])
            );

            aes_round_function round_inst (
                .data_in    (data_pipe[g]),
                .round_key  (next_key[g]),
                .last_round (g == (NSTAGES-2)),
                .data_out   (round_out[g])
            );
        end
    endgenerate

    always @(posedge clk) begin
        if (rst) begin
            for (i = 0; i < NSTAGES; i = i + 1) begin
                data_pipe[i]  <= 128'b0;
                key_pipe[i]   <= 128'b0;
                valid_pipe[i] <= 1'b0;
            end
            data_out  <= 128'b0;
            valid_out <= 1'b0;
            done      <= 1'b0;
        end else begin
            // Stage 0: initial AddRoundKey
            data_pipe[0]  <= init_data;
            key_pipe[0]   <= key_in;
            valid_pipe[0] <= valid_in && start;

            // Stages 1..NSTAGES-1
            for (i = 1; i < NSTAGES; i = i + 1) begin
                data_pipe[i]  <= round_out[i-1];
                key_pipe[i]   <= next_key[i-1];
                valid_pipe[i] <= valid_pipe[i-1];
            end

            data_out  <= data_pipe[NSTAGES-1];
            valid_out <= valid_pipe[NSTAGES-1];
            done      <= valid_pipe[NSTAGES-1];
        end
    end

endmodule