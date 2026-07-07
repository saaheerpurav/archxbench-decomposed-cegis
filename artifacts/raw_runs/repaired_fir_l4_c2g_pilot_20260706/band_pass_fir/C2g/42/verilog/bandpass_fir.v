`timescale 1ns/1ps

module bandpass_fir #(
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

    reg signed [DATA_W-1:0] delay [0:99];

    integer i;
    reg signed [63:0] acc;
    reg signed [DATA_W-1:0] sample;

    function signed [15:0] h;
        input integer k;
        begin
            case (k)
                0:h=16'sd16; 1:h=16'sd10; 2:h=16'sd6; 3:h=16'sd2; 4:h=16'sd0;
                5:h=16'sd1; 6:h=16'sd5; 7:h=16'sd13; 8:h=16'sd26; 9:h=16'sd42;
                10:h=16'sd59; 11:h=16'sd77; 12:h=16'sd90; 13:h=16'sd97; 14:h=16'sd93;
                15:h=16'sd77; 16:h=16'sd47; 17:h=16'sd5; 18:h=-16'sd45; 19:h=-16'sd99;
                20:h=-16'sd149; 21:h=-16'sd187; 22:h=-16'sd207; 23:h=-16'sd204; 24:h=-16'sd178;
                25:h=-16'sd132; 26:h=-16'sd73; 27:h=-16'sd14; 28:h=16'sd31; 29:h=16'sd46;
                30:h=16'sd16; 31:h=-16'sd67; 32:h=-16'sd208; 33:h=-16'sd403; 34:h=-16'sd638;
                35:h=-16'sd891; 36:h=-16'sd1134; 37:h=-16'sd1333; 38:h=-16'sd1455; 39:h=-16'sd1471;
                40:h=-16'sd1359; 41:h=-16'sd1111; 42:h=-16'sd730; 43:h=-16'sd235; 44:h=16'sd341;
                45:h=16'sd955; 46:h=16'sd1555; 47:h=16'sd2091; 48:h=16'sd2513; 49:h=16'sd2784;
                50:h=16'sd2877; 51:h=16'sd2784; 52:h=16'sd2513; 53:h=16'sd2091; 54:h=16'sd1555;
                55:h=16'sd955; 56:h=16'sd341; 57:h=-16'sd235; 58:h=-16'sd730; 59:h=-16'sd1111;
                60:h=-16'sd1359; 61:h=-16'sd1471; 62:h=-16'sd1455; 63:h=-16'sd1333; 64:h=-16'sd1134;
                65:h=-16'sd891; 66:h=-16'sd638; 67:h=-16'sd403; 68:h=-16'sd208; 69:h=-16'sd67;
                70:h=16'sd16; 71:h=16'sd46; 72:h=16'sd31; 73:h=-16'sd14; 74:h=-16'sd73;
                75:h=-16'sd132; 76:h=-16'sd178; 77:h=-16'sd204; 78:h=-16'sd207; 79:h=-16'sd187;
                80:h=-16'sd149; 81:h=-16'sd99; 82:h=-16'sd45; 83:h=16'sd5; 84:h=16'sd47;
                85:h=16'sd77; 86:h=16'sd93; 87:h=16'sd97; 88:h=16'sd90; 89:h=16'sd77;
                90:h=16'sd59; 91:h=16'sd42; 92:h=16'sd26; 93:h=16'sd13; 94:h=16'sd5;
                95:h=16'sd1; 96:h=16'sd0; 97:h=16'sd2; 98:h=16'sd6; 99:h=16'sd10;
                100:h=16'sd16;
                default:h=16'sd0;
            endcase
        end
    endfunction

    always @* begin
        sample = $signed(data_in);
        acc = $signed(sample) * $signed(h(0));

        for (i = 1; i < 101; i = i + 1)
            acc = acc + ($signed(delay[i-1]) * $signed(h(i)));
    end

    always @(posedge clk) begin
        if (rst) begin
            valid_out <= 1'b0;
            data_out  <= {OUT_W{1'b0}};
            for (i = 0; i < 100; i = i + 1)
                delay[i] <= {DATA_W{1'b0}};
        end else begin
            valid_out <= valid_in;

            if (valid_in) begin
                data_out <= acc >>> 20;

                for (i = 99; i > 0; i = i - 1)
                    delay[i] <= delay[i-1];
                delay[0] <= sample;
            end
        end
    end

endmodule