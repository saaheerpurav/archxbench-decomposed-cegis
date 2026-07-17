`timescale 1ns/1ps

module fp_lowpass_fir #(
    parameter TAP_CNT = 101
) (
    input wire clk,
    input wire rst,
    input wire valid_in,
    input wire [31:0] data_in,
    output wire valid_out,
    output wire [31:0] data_out
);

    reg [31:0] history [0:TAP_CNT-1];
    reg valid_out_r;
    reg [31:0] data_out_r;
    reg [TAP_CNT*32-1:0] flat_history;

    wire [TAP_CNT*32-1:0] next_history_bus;
    wire [31:0] fir_result;

    integer i;

    fp_fir_history_pack #(
        .TAP_CNT(TAP_CNT)
    ) u_history_pack (
        .new_sample(data_in),
        .history_bus(flat_history),
        .next_history_bus(next_history_bus)
    );

    fp_fir_mac #(
        .TAP_CNT(TAP_CNT)
    ) u_fir_mac (
        .sample_bus(next_history_bus),
        .result(fir_result)
    );

    always @(*) begin
        for (i = 0; i < TAP_CNT; i = i + 1)
            flat_history[i*32 +: 32] = history[i];
    end

    always @(posedge clk) begin
        if (rst) begin
            valid_out_r <= 1'b0;
            data_out_r <= 32'h00000000;
            for (i = 0; i < TAP_CNT; i = i + 1)
                history[i] <= 32'h00000000;
        end else begin
            valid_out_r <= valid_in;
            if (valid_in) begin
                data_out_r <= fir_result;
                history[0] <= data_in;
                for (i = 1; i < TAP_CNT; i = i + 1)
                    history[i] <= history[i-1];
            end
        end
    end

    assign valid_out = valid_out_r;
    assign data_out = data_out_r;

endmodule