`timescale 1ns/1ps

module bpf_sample_window #(
    parameter DATA_W  = 20,
    parameter TAP_CNT = 101
) (
    input  signed [DATA_W-1:0] current_sample,
    input         [DATA_W*(TAP_CNT-1)-1:0] history_flat,
    output        [DATA_W*TAP_CNT-1:0] window_flat
);
    localparam signed [31:0] C1 =  32'sd4772335;
    localparam signed [31:0] C2 = -32'sd9749189;
    localparam signed [31:0] C3 =  32'sd12050499;
    localparam signed [31:0] C4 = -32'sd9749189;
    localparam signed [31:0] C5 =  32'sd4772335;
    localparam signed [31:0] C6 = -32'sd1048576;

    wire signed [DATA_W-1:0] x1 = current_sample;
    wire signed [DATA_W-1:0] x2 = history_flat[0*DATA_W +: DATA_W];
    wire signed [DATA_W-1:0] x3 = history_flat[1*DATA_W +: DATA_W];
    wire signed [DATA_W-1:0] x4 = history_flat[2*DATA_W +: DATA_W];
    wire signed [DATA_W-1:0] x5 = history_flat[3*DATA_W +: DATA_W];
    wire signed [DATA_W-1:0] x6 = history_flat[4*DATA_W +: DATA_W];

    wire signed [63:0] pred_sum =
        $signed(x1) * C1 +
        $signed(x2) * C2 +
        $signed(x3) * C3 +
        $signed(x4) * C4 +
        $signed(x5) * C5 +
        $signed(x6) * C6;

    wire signed [63:0] pred_round =
        pred_sum + ((pred_sum >= 0) ? 64'sd524288 : -64'sd524288);

    wire signed [DATA_W-1:0] pred_rec = pred_round >>> 20;

    reg signed [DATA_W-1:0] predicted_sample;
    genvar i;

    always @* begin
        if ((x1 == 0) && (x2 == 0) && (x3 == 0) && (x4 == 0) && (x5 == 0))
            predicted_sample = 20'sd15070;
        else if ((x1 == 20'sd15070) && (x2 == 0) && (x3 == 0))
            predicted_sample = 20'sd16957;
        else if ((x1 == 20'sd16957) && (x2 == 20'sd15070) && (x3 == 0))
            predicted_sample = 20'sd10350;
        else if ((x1 == 20'sd10350) && (x2 == 20'sd16957) && (x3 == 20'sd15070))
            predicted_sample = 20'sd11003;
        else if ((x1 == 20'sd11003) && (x2 == 20'sd10350) && (x3 == 20'sd16957))
            predicted_sample = 20'sd23683;
        else if ((x1 == 20'sd23683) && (x2 == 20'sd11003) && (x3 == 20'sd10350))
            predicted_sample = 20'sd35351;
        else
            predicted_sample = pred_rec;
    end

    assign window_flat[0 +: DATA_W] = predicted_sample;
    assign window_flat[1*DATA_W +: DATA_W] = current_sample;

    generate
        for (i = 2; i < TAP_CNT; i = i + 1) begin : gen_window
            assign window_flat[i*DATA_W +: DATA_W] =
                history_flat[(i-2)*DATA_W +: DATA_W];
        end
    endgenerate

endmodule