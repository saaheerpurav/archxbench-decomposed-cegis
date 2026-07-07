`timescale 1ns/1ps

module fp_bandpass_coeff #(
    parameter INDEX   = 0,
    parameter COEFF_Q = 24
) (
    output signed [31:0] coeff_q
);
    reg signed [31:0] c;

    always @* begin
        case (INDEX)
             0: c = -32'sd45164;
             1: c = -32'sd62898;
             2: c = -32'sd95873;
             3: c = -32'sd143177;
             4: c = -32'sd195941;
             5: c = -32'sd237096;
             6: c = -32'sd244327;
             7: c = -32'sd195371;
             8: c = -32'sd74155;
             9: c =  32'sd123396;
            10: c =  32'sd385960;
            11: c =  32'sd686658;
            12: c =  32'sd986888;
            13: c =  32'sd1243105;
            14: c =  32'sd1415578;
            15: c =  32'sd1476395;
            16: c =  32'sd1415578;
            17: c =  32'sd1243105;
            18: c =  32'sd986888;
            19: c =  32'sd686658;
            20: c =  32'sd385960;
            21: c =  32'sd123396;
            22: c = -32'sd74155;
            23: c = -32'sd195371;
            24: c = -32'sd244327;
            25: c = -32'sd237096;
            26: c = -32'sd195941;
            27: c = -32'sd143177;
            28: c = -32'sd95873;
            29: c = -32'sd62898;
            30: c = -32'sd45164;
            default: c = 32'sd0;
        endcase
    end

    assign coeff_q = c;
endmodule