`timescale 1ns/1ps

module dct8_coeff_matrix #(
    parameter COEFF_W = 16
) (
    input mode,
    input [2:0] out_index,
    output reg signed [COEFF_W-1:0] c0,
    output reg signed [COEFF_W-1:0] c1,
    output reg signed [COEFF_W-1:0] c2,
    output reg signed [COEFF_W-1:0] c3,
    output reg signed [COEFF_W-1:0] c4,
    output reg signed [COEFF_W-1:0] c5,
    output reg signed [COEFF_W-1:0] c6,
    output reg signed [COEFF_W-1:0] c7
);

    always @* begin
        case ({mode, out_index})
            4'b0_000: begin c0=16'sd5793; c1=16'sd5793; c2=16'sd5793; c3=16'sd5793; c4=16'sd5793; c5=16'sd5793; c6=16'sd5793; c7=16'sd5793; end
            4'b0_001: begin c0=16'sd8035; c1=16'sd6811; c2=16'sd4551; c3=16'sd1598; c4=-16'sd1598; c5=-16'sd4551; c6=-16'sd6811; c7=-16'sd8035; end
            4'b0_010: begin c0=16'sd7568; c1=16'sd3135; c2=-16'sd3135; c3=-16'sd7568; c4=-16'sd7568; c5=-16'sd3135; c6=16'sd3135; c7=16'sd7568; end
            4'b0_011: begin c0=16'sd6811; c1=-16'sd1598; c2=-16'sd8035; c3=-16'sd4551; c4=16'sd4551; c5=16'sd8035; c6=16'sd1598; c7=-16'sd6811; end
            4'b0_100: begin c0=16'sd5793; c1=-16'sd5793; c2=-16'sd5793; c3=16'sd5793; c4=16'sd5793; c5=-16'sd5793; c6=-16'sd5793; c7=16'sd5793; end
            4'b0_101: begin c0=16'sd4551; c1=-16'sd8035; c2=16'sd1598; c3=16'sd6811; c4=-16'sd6811; c5=-16'sd1598; c6=16'sd8035; c7=-16'sd4551; end
            4'b0_110: begin c0=16'sd3135; c1=-16'sd7568; c2=16'sd7568; c3=-16'sd3135; c4=-16'sd3135; c5=16'sd7568; c6=-16'sd7568; c7=16'sd3135; end
            4'b0_111: begin c0=16'sd1598; c1=-16'sd4551; c2=16'sd6811; c3=-16'sd8035; c4=16'sd8035; c5=-16'sd6811; c6=16'sd4551; c7=-16'sd1598; end

            4'b1_000: begin c0=16'sd5793; c1=16'sd8035; c2=16'sd7568; c3=16'sd6811; c4=16'sd5793; c5=16'sd4551; c6=16'sd3135; c7=16'sd1598; end
            4'b1_001: begin c0=16'sd5793; c1=16'sd6811; c2=16'sd3135; c3=-16'sd1598; c4=-16'sd5793; c5=-16'sd8035; c6=-16'sd7568; c7=-16'sd4551; end
            4'b1_010: begin c0=16'sd5793; c1=16'sd4551; c2=-16'sd3135; c3=-16'sd8035; c4=-16'sd5793; c5=16'sd1598; c6=16'sd7568; c7=16'sd6811; end
            4'b1_011: begin c0=16'sd5793; c1=16'sd1598; c2=-16'sd7568; c3=-16'sd4551; c4=16'sd5793; c5=16'sd6811; c6=-16'sd3135; c7=-16'sd8035; end
            4'b1_100: begin c0=16'sd5793; c1=-16'sd1598; c2=-16'sd7568; c3=16'sd4551; c4=16'sd5793; c5=-16'sd6811; c6=-16'sd3135; c7=16'sd8035; end
            4'b1_101: begin c0=16'sd5793; c1=-16'sd4551; c2=-16'sd3135; c3=16'sd8035; c4=-16'sd5793; c5=-16'sd1598; c6=16'sd7568; c7=-16'sd6811; end
            4'b1_110: begin c0=16'sd5793; c1=-16'sd6811; c2=16'sd3135; c3=16'sd1598; c4=-16'sd5793; c5=16'sd8035; c6=-16'sd7568; c7=16'sd4551; end
            default:  begin c0=16'sd5793; c1=-16'sd8035; c2=16'sd7568; c3=-16'sd6811; c4=16'sd5793; c5=-16'sd4551; c6=16'sd3135; c7=-16'sd1598; end
        endcase
    end

endmodule