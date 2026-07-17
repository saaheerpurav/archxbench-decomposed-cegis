`timescale 1ns/1ps

module fir_symmetric_mac #(
    parameter DATA_W  = 20,
    parameter TAP_CNT = 101
) (
    input  [TAP_CNT*DATA_W-1:0] sample_flat,
    output reg signed [63:0] acc
);
    localparam HALF = TAP_CNT / 2;
    localparam CENTER = TAP_CNT / 2;

    wire signed [DATA_W-1:0] samples [0:TAP_CNT-1];
    wire signed [DATA_W:0] pair_sum [0:HALF-1];

    integer i;
    reg signed [15:0] coeff;
    reg signed [63:0] tmp;

    genvar g;
    generate
        for (g = 0; g < TAP_CNT; g = g + 1) begin : gen_samples
            assign samples[g] = sample_flat[g*DATA_W +: DATA_W];
        end

        for (g = 0; g < HALF; g = g + 1) begin : gen_pairs
            fir_pair_sum #(
                .DATA_W(DATA_W)
            ) u_pair_sum (
                .a(samples[g]),
                .b(samples[TAP_CNT-1-g]),
                .sum(pair_sum[g])
            );
        end
    endgenerate

    always @* begin
        tmp = 64'sd0;

        for (i = 0; i < HALF; i = i + 1) begin
            case (i[6:0])
                7'd0: coeff = 16'sd0;
                7'd1: coeff = -16'sd2;
                7'd2: coeff = -16'sd5;
                7'd3: coeff = -16'sd7;
                7'd4: coeff = -16'sd10;
                7'd5: coeff = -16'sd14;
                7'd6: coeff = -16'sd18;
                7'd7: coeff = -16'sd23;
                7'd8: coeff = -16'sd29;
                7'd9: coeff = -16'sd35;
                7'd10: coeff = -16'sd41;
                7'd11: coeff = -16'sd49;
                7'd12: coeff = -16'sd56;
                7'd13: coeff = -16'sd63;
                7'd14: coeff = -16'sd70;
                7'd15: coeff = -16'sd76;
                7'd16: coeff = -16'sd81;
                7'd17: coeff = -16'sd85;
                7'd18: coeff = -16'sd86;
                7'd19: coeff = -16'sd85;
                7'd20: coeff = -16'sd81;
                7'd21: coeff = -16'sd73;
                7'd22: coeff = -16'sd62;
                7'd23: coeff = -16'sd46;
                7'd24: coeff = -16'sd26;
                7'd25: coeff = 16'sd0;
                7'd26: coeff = 16'sd31;
                7'd27: coeff = 16'sd67;
                7'd28: coeff = 16'sd109;
                7'd29: coeff = 16'sd156;
                7'd30: coeff = 16'sd208;
                7'd31: coeff = 16'sd266;
                7'd32: coeff = 16'sd327;
                7'd33: coeff = 16'sd393;
                7'd34: coeff = 16'sd462;
                7'd35: coeff = 16'sd534;
                7'd36: coeff = 16'sd607;
                7'd37: coeff = 16'sd682;
                7'd38: coeff = 16'sd756;
                7'd39: coeff = 16'sd830;
                7'd40: coeff = 16'sd901;
                7'd41: coeff = 16'sd970;
                7'd42: coeff = 16'sd1034;
                7'd43: coeff = 16'sd1094;
                7'd44: coeff = 16'sd1147;
                7'd45: coeff = 16'sd1194;
                7'd46: coeff = 16'sd1233;
                7'd47: coeff = 16'sd1265;
                7'd48: coeff = 16'sd1287;
                7'd49: coeff = 16'sd1301;
                default: coeff = 16'sd0;
            endcase
            tmp = tmp + ($signed(pair_sum[i]) * $signed(coeff));
        end

        tmp = tmp + ($signed(samples[CENTER]) * 16'sd1306);
        acc = tmp;
    end
endmodule