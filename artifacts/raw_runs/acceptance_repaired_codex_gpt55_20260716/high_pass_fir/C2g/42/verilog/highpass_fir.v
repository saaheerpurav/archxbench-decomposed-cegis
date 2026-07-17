`timescale 1ns/1ps

module highpass_fir #(
    parameter DATA_W  = 20,
    parameter TAP_CNT = 101,
    parameter GAIN_W  = 4
) (
    input                              clk,
    input                              rst,
    input                              valid_in,
    input      [DATA_W-1:0]            data_in,
    output reg                         valid_out,
    output reg signed [DATA_W+GAIN_W-1:0] data_out
);

    localparam OUT_W = DATA_W + GAIN_W;

    reg signed [DATA_W-1:0] sample_cap;
    reg signed [DATA_W-1:0] sample_use;
    reg                     valid_cap;
    reg                     valid_use;

    reg signed [DATA_W-1:0] delay_line [0:TAP_CNT-2];
    reg signed [OUT_W-1:0]  result_pipe;

    integer i;
    integer k;
    reg signed [63:0] acc;

    function signed [31:0] coeff;
        input integer idx;
        begin
            case (idx)
                0: coeff = 0;       1: coeff = 10;      2: coeff = 17;
                3: coeff = 19;      4: coeff = 13;      5: coeff = 0;
                6: coeff = -16;     7: coeff = -29;     8: coeff = -32;
                9: coeff = -23;     10: coeff = 0;      11: coeff = 29;
                12: coeff = 53;     13: coeff = 60;     14: coeff = 42;
                15: coeff = 0;      16: coeff = -53;    17: coeff = -96;
                18: coeff = -107;   19: coeff = -73;    20: coeff = 0;
                21: coeff = 90;     22: coeff = 161;    23: coeff = 177;
                24: coeff = 121;    25: coeff = 0;      26: coeff = -145;
                27: coeff = -258;   28: coeff = -282;   29: coeff = -191;
                30: coeff = 0;      31: coeff = 229;    32: coeff = 406;
                33: coeff = 444;    34: coeff = 301;    35: coeff = 0;
                36: coeff = -365;   37: coeff = -652;   38: coeff = -724;
                39: coeff = -499;   40: coeff = 0;      41: coeff = 633;
                42: coeff = 1170;   43: coeff = 1355;   44: coeff = 989;
                45: coeff = 0;      46: coeff = -1511;  47: coeff = -3280;
                48: coeff = -4943;  49: coeff = -6126;  50: coeff = 26219;
                51: coeff = -6126;  52: coeff = -4943;  53: coeff = -3280;
                54: coeff = -1511;  55: coeff = 0;      56: coeff = 989;
                57: coeff = 1355;   58: coeff = 1170;   59: coeff = 633;
                60: coeff = 0;      61: coeff = -499;   62: coeff = -724;
                63: coeff = -652;   64: coeff = -365;   65: coeff = 0;
                66: coeff = 301;    67: coeff = 444;    68: coeff = 406;
                69: coeff = 229;    70: coeff = 0;      71: coeff = -191;
                72: coeff = -282;   73: coeff = -258;   74: coeff = -145;
                75: coeff = 0;      76: coeff = 121;    77: coeff = 177;
                78: coeff = 161;    79: coeff = 90;     80: coeff = 0;
                81: coeff = -73;    82: coeff = -107;   83: coeff = -96;
                84: coeff = -53;    85: coeff = 0;      86: coeff = 42;
                87: coeff = 60;     88: coeff = 53;     89: coeff = 29;
                90: coeff = 0;      91: coeff = -23;    92: coeff = -32;
                93: coeff = -29;    94: coeff = -16;    95: coeff = 0;
                96: coeff = 13;     97: coeff = 19;     98: coeff = 17;
                99: coeff = 10;     100: coeff = 0;
                default: coeff = 0;
            endcase
        end
    endfunction

    function signed [63:0] mul64;
        input signed [DATA_W-1:0] sample;
        input signed [31:0] c;
        begin
            mul64 = $signed({{(64-DATA_W){sample[DATA_W-1]}}, sample}) *
                    $signed({{32{c[31]}}, c});
        end
    endfunction

    always @(negedge clk) begin
        sample_use <= sample_cap;
        valid_use  <= valid_cap;
        sample_cap <= $signed(data_in);
        valid_cap  <= valid_in;
    end

    always @(posedge clk) begin
        if (rst) begin
            sample_cap  <= {DATA_W{1'b0}};
            sample_use  <= {DATA_W{1'b0}};
            valid_cap   <= 1'b0;
            valid_use   <= 1'b0;
            valid_out   <= 1'b0;
            data_out    <= {OUT_W{1'b0}};
            result_pipe <= {OUT_W{1'b0}};

            for (i = 0; i < TAP_CNT-1; i = i + 1)
                delay_line[i] <= {DATA_W{1'b0}};
        end else begin
            valid_out <= valid_use;

            if (valid_use) begin
                data_out <= result_pipe;

                acc = mul64(sample_use, coeff(1));
                for (k = 1; k < TAP_CNT-1; k = k + 1)
                    acc = acc + mul64(delay_line[k-1], coeff(k+1));

                result_pipe <= acc >>> 15;

                for (i = TAP_CNT-2; i > 0; i = i - 1)
                    delay_line[i] <= delay_line[i-1];
                delay_line[0] <= sample_use;
            end
        end
    end

endmodule