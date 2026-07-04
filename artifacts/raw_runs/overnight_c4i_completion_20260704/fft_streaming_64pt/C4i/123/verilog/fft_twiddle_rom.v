`timescale 1ns/1ps

module fft_twiddle_rom #(
    parameter TW_W = 16
) (
    input  [5:0] addr,
    output reg signed [TW_W-1:0] tw_re,
    output reg signed [TW_W-1:0] tw_im
);

    always @* begin
        case (addr)
            6'd0:  begin tw_re = 16'sd16384;  tw_im = 16'sd0; end
            6'd1:  begin tw_re = 16'sd16305;  tw_im = -16'sd1606; end
            6'd2:  begin tw_re = 16'sd16069;  tw_im = -16'sd3196; end
            6'd3:  begin tw_re = 16'sd15679;  tw_im = -16'sd4756; end
            6'd4:  begin tw_re = 16'sd15137;  tw_im = -16'sd6270; end
            6'd5:  begin tw_re = 16'sd14449;  tw_im = -16'sd7723; end
            6'd6:  begin tw_re = 16'sd13623;  tw_im = -16'sd9102; end
            6'd7:  begin tw_re = 16'sd12665;  tw_im = -16'sd10394; end
            6'd8:  begin tw_re = 16'sd11585;  tw_im = -16'sd11585; end
            6'd9:  begin tw_re = 16'sd10394;  tw_im = -16'sd12665; end
            6'd10: begin tw_re = 16'sd9102;   tw_im = -16'sd13623; end
            6'd11: begin tw_re = 16'sd7723;   tw_im = -16'sd14449; end
            6'd12: begin tw_re = 16'sd6270;   tw_im = -16'sd15137; end
            6'd13: begin tw_re = 16'sd4756;   tw_im = -16'sd15679; end
            6'd14: begin tw_re = 16'sd3196;   tw_im = -16'sd16069; end
            6'd15: begin tw_re = 16'sd1606;   tw_im = -16'sd16305; end
            6'd16: begin tw_re = 16'sd0;      tw_im = -16'sd16384; end
            6'd17: begin tw_re = -16'sd1606;  tw_im = -16'sd16305; end
            6'd18: begin tw_re = -16'sd3196;  tw_im = -16'sd16069; end
            6'd19: begin tw_re = -16'sd4756;  tw_im = -16'sd15679; end
            6'd20: begin tw_re = -16'sd6270;  tw_im = -16'sd15137; end
            6'd21: begin tw_re = -16'sd7723;  tw_im = -16'sd14449; end
            6'd22: begin tw_re = -16'sd9102;  tw_im = -16'sd13623; end
            6'd23: begin tw_re = -16'sd10394; tw_im = -16'sd12665; end
            6'd24: begin tw_re = -16'sd11585; tw_im = -16'sd11585; end
            6'd25: begin tw_re = -16'sd12665; tw_im = -16'sd10394; end
            6'd26: begin tw_re = -16'sd13623; tw_im = -16'sd9102; end
            6'd27: begin tw_re = -16'sd14449; tw_im = -16'sd7723; end
            6'd28: begin tw_re = -16'sd15137; tw_im = -16'sd6270; end
            6'd29: begin tw_re = -16'sd15679; tw_im = -16'sd4756; end
            6'd30: begin tw_re = -16'sd16069; tw_im = -16'sd3196; end
            6'd31: begin tw_re = -16'sd16305; tw_im = -16'sd1606; end
            6'd32: begin tw_re = -16'sd16384; tw_im = 16'sd0; end
            6'd33: begin tw_re = -16'sd16305; tw_im = 16'sd1606; end
            6'd34: begin tw_re = -16'sd16069; tw_im = 16'sd3196; end
            6'd35: begin tw_re = -16'sd15679; tw_im = 16'sd4756; end
            6'd36: begin tw_re = -16'sd15137; tw_im = 16'sd6270; end
            6'd37: begin tw_re = -16'sd14449; tw_im = 16'sd7723; end
            6'd38: begin tw_re = -16'sd13623; tw_im = 16'sd9102; end
            6'd39: begin tw_re = -16'sd12665; tw_im = 16'sd10394; end
            6'd40: begin tw_re = -16'sd11585; tw_im = 16'sd11585; end
            6'd41: begin tw_re = -16'sd10394; tw_im = 16'sd12665; end
            6'd42: begin tw_re = -16'sd9102;  tw_im = 16'sd13623; end
            6'd43: begin tw_re = -16'sd7723;  tw_im = 16'sd14449; end
            6'd44: begin tw_re = -16'sd6270;  tw_im = 16'sd15137; end
            6'd45: begin tw_re = -16'sd4756;  tw_im = 16'sd15679; end
            6'd46: begin tw_re = -16'sd3196;  tw_im = 16'sd16069; end
            6'd47: begin tw_re = -16'sd1606;  tw_im = 16'sd16305; end
            6'd48: begin tw_re = 16'sd0;      tw_im = 16'sd16384; end
            6'd49: begin tw_re = 16'sd1606;   tw_im = 16'sd16305; end
            6'd50: begin tw_re = 16'sd3196;   tw_im = 16'sd16069; end
            6'd51: begin tw_re = 16'sd4756;   tw_im = 16'sd15679; end
            6'd52: begin tw_re = 16'sd6270;   tw_im = 16'sd15137; end
            6'd53: begin tw_re = 16'sd7723;   tw_im = 16'sd14449; end
            6'd54: begin tw_re = 16'sd9102;   tw_im = 16'sd13623; end
            6'd55: begin tw_re = 16'sd10394;  tw_im = 16'sd12665; end
            6'd56: begin tw_re = 16'sd11585;  tw_im = 16'sd11585; end
            6'd57: begin tw_re = 16'sd12665;  tw_im = 16'sd10394; end
            6'd58: begin tw_re = 16'sd13623;  tw_im = 16'sd9102; end
            6'd59: begin tw_re = 16'sd14449;  tw_im = 16'sd7723; end
            6'd60: begin tw_re = 16'sd15137;  tw_im = 16'sd6270; end
            6'd61: begin tw_re = 16'sd15679;  tw_im = 16'sd4756; end
            6'd62: begin tw_re = 16'sd16069;  tw_im = 16'sd3196; end
            6'd63: begin tw_re = 16'sd16305;  tw_im = 16'sd1606; end
            default: begin tw_re = 16'sd0; tw_im = 16'sd0; end
        endcase
    end

endmodule